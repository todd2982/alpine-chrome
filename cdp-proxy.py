#!/usr/bin/env python3
"""
cdp-proxy.py - Chrome DevTools Protocol proxy.

Listens on EXTERNAL_PORT (default 9222) and proxies to Chrome's internal
DevTools server on INTERNAL_PORT (default 9223, bound to 127.0.0.1).

Two types of traffic:
  1. HTTP JSON endpoints (/json, /json/list, /json/version, etc.):
     Fetched from Chrome and returned with 127.0.0.1:<internal> rewritten
     to the client-facing host:port so CDP clients get usable WebSocket URLs.
  2. WebSocket upgrade requests:
     Forwarded as raw TCP after passing the upgrade handshake through,
     then proxied bidirectionally so CDP commands work.
"""

import os
import select
import socket
import threading
import urllib.request
import urllib.error

INTERNAL_PORT = int(os.environ.get("CHROME_INTERNAL_PORT", "9223"))
EXTERNAL_PORT = int(os.environ.get("CHROME_EXTERNAL_PORT", "9222"))


def pipe_raw(src: socket.socket, dst: socket.socket) -> None:
    """Forward bytes from src to dst until one side closes."""
    try:
        while True:
            ready, _, _ = select.select([src], [], [], 10)
            if not ready:
                continue
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except OSError:
        pass
    finally:
        for s in (src, dst):
            try:
                s.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            try:
                s.close()
            except OSError:
                pass


def handle_websocket(client: socket.socket, initial_data: bytes) -> None:
    """Proxy a WebSocket connection to Chrome's internal port."""
    internal = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        internal.connect(("127.0.0.1", INTERNAL_PORT))
    except OSError as exc:
        print(f"[cdp-proxy] Cannot connect to internal Chrome: {exc}")
        client.close()
        return

    # Forward the original HTTP upgrade request
    internal.sendall(initial_data)

    # Bidirectional relay
    t = threading.Thread(target=pipe_raw, args=(internal, client), daemon=True)
    t.start()
    pipe_raw(client, internal)
    t.join(timeout=5)


def handle_http(client: socket.socket, request_line: str, headers: dict) -> None:
    """Proxy a regular HTTP request, rewriting internal addresses in the response."""
    parts = request_line.split(" ", 2)
    if len(parts) < 2:
        client.close()
        return

    path = parts[1]
    url = f"http://127.0.0.1:{INTERNAL_PORT}{path}"

    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            content_type = resp.getheader("Content-Type", "application/json")
            raw = resp.read()
    except urllib.error.URLError as exc:
        msg = f"[cdp-proxy] Upstream error for {path}: {exc}".encode()
        response = (
            b"HTTP/1.1 502 Bad Gateway\r\n"
            b"Content-Type: text/plain\r\n"
            + f"Content-Length: {len(msg)}\r\n".encode()
            + b"Connection: close\r\n\r\n" + msg
        )
        try:
            client.sendall(response)
        except OSError:
            pass
        client.close()
        return

    # Rewrite internal addresses in JSON responses so clients get usable WS URLs.
    # Use the Host header so the URL works regardless of how the container is reached.
    host = headers.get("host", f"localhost:{EXTERNAL_PORT}")
    try:
        content = raw.decode("utf-8")
        content = content.replace(f"127.0.0.1:{INTERNAL_PORT}", host)
        content = content.replace(f"localhost:{INTERNAL_PORT}", host)
        body = content.encode("utf-8")
    except (UnicodeDecodeError, ValueError):
        body = raw  # Non-text response; pass through untouched

    response = (
        b"HTTP/1.1 200 OK\r\n"
        + f"Content-Type: {content_type}\r\n".encode()
        + f"Content-Length: {len(body)}\r\n".encode()
        + b"Connection: close\r\n\r\n"
        + body
    )
    try:
        client.sendall(response)
    except OSError:
        pass
    client.close()


def read_http_headers(sock: socket.socket):
    """Read raw bytes from sock until the end of HTTP headers. Returns (raw_bytes, header_lines)."""
    data = b""
    while b"\r\n\r\n" not in data:
        chunk = sock.recv(4096)
        if not chunk:
            return None, None
        data += chunk
        if len(data) > 65536:  # Guard against oversized headers
            return None, None
    return data, data.split(b"\r\n\r\n", 1)[0].decode("utf-8", errors="replace").split("\r\n")


def handle_connection(client: socket.socket, _addr) -> None:
    try:
        raw, header_lines = read_http_headers(client)
        if raw is None or not header_lines:
            client.close()
            return

        request_line = header_lines[0]
        headers = {}
        for line in header_lines[1:]:
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip().lower()] = v.strip()

        if headers.get("upgrade", "").lower() == "websocket":
            handle_websocket(client, raw)
        else:
            handle_http(client, request_line, headers)
    except OSError:
        try:
            client.close()
        except OSError:
            pass


def main() -> None:
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", EXTERNAL_PORT))
    server.listen(128)
    print(f"[cdp-proxy] Listening on 0.0.0.0:{EXTERNAL_PORT} -> 127.0.0.1:{INTERNAL_PORT}")

    while True:
        try:
            client, addr = server.accept()
        except OSError:
            break
        t = threading.Thread(target=handle_connection, args=(client, addr), daemon=True)
        t.start()


if __name__ == "__main__":
    main()
