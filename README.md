[![GitHub Stars](https://img.shields.io/github/stars/todd2982/alpine-chrome)](https://github.com/todd2982/alpine-chrome/) [![Docker Build Status](https://img.shields.io/github/actions/workflow/status/todd2982/alpine-chrome/build.yml)](https://github.com/todd2982/alpine-chrome/actions/workflows/build.yml)


# alpine-chrome (fork)

Chrome running in headless mode in a tiny Alpine image

Thank you to the original alpine-chrome team for all the heavy lifting!
This repository simply continues regular builds of the original project (with more recent Chrome versions) as the original is [no longer maintained](https://github.com/jlandure/alpine-chrome/pull/257#issuecomment-2727201437)

****

# Available registries
- On [GitHub Container registry](https://github.com/todd2982/alpine-chrome/pkgs/container/alpine-chrome): `ghcr.io/todd2982/alpine-chrome`

Currently the image is only on GHCR, if you have another registry that you would like me to push to, please create an issue.

# Supported tags and respective `Dockerfile` links

- `latest`, `100` [(Dockerfile)](https://github.com/todd2982/alpine-chrome/blob/master/Dockerfile)
- `with-node`, `100-with-node`, `100-with-node-16` [(Dockerfile)](https://github.com/todd2982/alpine-chrome/blob/master/with-node/Dockerfile)
- `with-puppeteer`, `100-with-puppeteer` [(Dockerfile)](https://github.com/todd2982/alpine-chrome/blob/master/with-puppeteer/Dockerfile)
- `with-playwright`, `100-with-playwright` [(Dockerfile)](https://github.com/todd2982/alpine-chrome/blob/master/with-playwright/Dockerfile)
- `with-selenoid`, `100-with-selenoid` [(Dockerfile)](https://github.com/todd2982/alpine-chrome/blob/master/with-selenoid/Dockerfile)
- `with-chromedriver`, `100-with-chromedriver` [(Dockerfile)](https://github.com/todd2982/alpine-chrome/blob/master/with-chromedriver/Dockerfile)
- `89`, `86`, `85`, `84`, `83`, `81`, `80`, `77`, `76`, `73`, `72`, `71`, `68`, `64`
- `89-with-node`, `86-with-node`, `85-with-node`, `84-with-node`, `83-with-node`, `81-with-node`, `80-with-node`, `77-with-node`, `76-with-node`
- `89-with-puppeteer`, `86-with-puppeteer`, `85-with-puppeteer`,`84-with-puppeteer`, `83-with-puppeteer`, `81-with-puppeteer`, `80-with-puppeteer`, `77-with-puppeteer`, `76-with-puppeteer`



# 🤔 Why use a Headless Chrome

In the world of webdev, the ability to run quickly end-to-end tests are important. Popular technologies like Puppeteer enable developers to make fun things like testing, automating forms, crawling, generating screenshots, capturing timeline... And there is a secret: some of these features are directly available on Chrome! 🙌

## 💡 Crafting the perfect container

- 📦 Tiniest Headless Chrome (Compressed size: [423 MB](https://github.com/todd2982/alpine-chrome#image-disk-size))
- 🐳 Easy to use, ephemeral and reproducible Headless Chrome with Docker
- 📝 Doc-friendly with examples for printing the DOM, generating an image with a mobile ratio or generating a PDF.
- 👷‍♂️ Autobuild with Github Actions to sync the project and ship the images with confidence
- 📌 Up-to-date latest Chromium and tags available to test different versions of Chromium
- 🔐 Secure with the best way to use Chrome and Docker - [See "3 ways to securely use Chrome Headless"](https://github.com/todd2982/alpine-chrome#3-ways-to-securely-use-chrome-headless-with-this-image) section
- 🌐 Ready for internationalisation use: support for asian characters - [See "screenshot-asia.js" file](https://github.com/todd2982/alpine-chrome/blob/master/with-puppeteer/src/screenshot-asia.js)
- 💄 Ready for design use: support for WebGL, support for emojis- See ["How to use with WebGL" section](https://github.com/todd2982/alpine-chrome#how-to-use-with-webgl) and ["Emojis are not rendered properly" section](https://github.com/todd2982/alpine-chrome/issues/114)
- 📄 Open Source with an Apache2 licence
- 👥 Community-built with external contributors - [See "✨ Contributors" section](https://github.com/todd2982/alpine-chrome#-contributors)
- 💚 Dev-friendly with examples using NodeJS, Puppeteer, docker-compose and also a test with a X11 display - [See "Run examples" section](https://github.com/todd2982/alpine-chrome#run-examples)

# 3 ways to securely use Chrome Headless with this image

## ❌ With nothing

Launching the container using only `docker container run -it ghcr.io/todd2982/alpine-chrome ...` will fail with some logs similar to [#33](https://github.com/todd2982/alpine-chrome/issues/33).

Please use the 3 others ways to use Chrome Headless.

## ✅ With `--no-sandbox`

Launch the container using:

`docker container run -it --rm ghcr.io/todd2982/alpine-chrome` and use the `--no-sandbox` flag for all your commands.

Be careful to know the website you're calling.

Explanation for the `no-sandbox` flag in a [quick introduction here](https://www.google.com/googlebooks/chrome/med_26.html) and for [More in depth design document here](https://chromium.googlesource.com/chromium/src/+/master/docs/design/sandbox.md)

## ✅ With `SYS_ADMIN` capability

Launch the container using:
`docker container run -it --rm --cap-add=SYS_ADMIN ghcr.io/todd2982/alpine-chrome`

This allows to run Chrome with sandboxing but needs unnecessary privileges from a Docker point of view.

## ✅ The best: With `seccomp`

Thanks to ever-awesome Jessie Frazelle seccomp profile for Chrome. This is The most secure way to run this Headless Chrome docker image.

[chrome.json](https://github.com/todd2982/alpine-chrome/blob/master/chrome.json)

Also available here `wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json`

Launch the container using:
`docker container run -it --rm --security-opt seccomp=$(pwd)/chrome.json ghcr.io/todd2982/alpine-chrome`

# How to use in command line

## Default entrypoint

The default entrypoint runs `chromium-browser --headless` with some common flags from `CHROMIUM_FLAGS` set in the [`Dockerfile`](./Dockerfile).

You can change the `CHROMIUM_FLAGS` by overriding the environment variable using: `docker container run -it --rm --env CHROMIUM_FLAGS="--other-flag ..." ghcr.io/todd2982/alpine-chrome chromium-browser ...`

You can get full control by overriding the entrypoint using: `docker container run -it --rm --entrypoint "" ghcr.io/todd2982/alpine-chrome chromium-browser ...`

## Use the devtools

Command (with no-sandbox): `docker container run -d -p 9222:9222 ghcr.io/todd2982/alpine-chrome --no-sandbox --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 https://www.chromestatus.com/`

Open your browser to: `http://localhost:9222` and then click on the tab you want to inspect. Replace the beginning
`https://chrome-devtools-frontend.appspot.com/serve_file/@.../inspector.html?ws=localhost:9222/[END]`
by
`chrome-devtools://devtools/bundled/inspector.html?ws=localhost:9222/[END]`

## Print the DOM

Command (with no-sandbox): `docker container run -it --rm ghcr.io/todd2982/alpine-chrome --no-sandbox --dump-dom https://www.chromestatus.com/`

## Print a PDF

Command (with no-sandbox): `docker container run -it --rm -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --no-sandbox --print-to-pdf --hide-scrollbars https://www.chromestatus.com/`

## Take a screenshot

Command (with no-sandbox): `docker container run -it --rm -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --no-sandbox --screenshot --hide-scrollbars https://www.chromestatus.com/`

### Size of a standard letterhead.

Command (with no-sandbox): `docker container run -it --rm -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --no-sandbox --screenshot --hide-scrollbars --window-size=1280,1696 https://www.chromestatus.com/`

### Nexus 5x

Command (with no-sandbox): `docker container run -it --rm -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --no-sandbox --screenshot --hide-scrollbars --window-size=412,732 https://www.chromestatus.com/`

### Screenshot owned by current user (by default the file is owned by the container user)

Command (with no-sandbox): `` docker container run -u `id -u $USER` -it --rm -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --no-sandbox --screenshot --hide-scrollbars --window-size=412,732 https://www.chromestatus.com/ ``

# How to use with Deno

Go the deno `src` folder. Build your image using this command:

```shell
docker image build -t ghcr.io/todd2982/alpine-chrome:with-deno-sample .
```

Then launch the container:

```shell
docker container run -it --rm ghcr.io/todd2982/alpine-chrome:with-deno-sample
 Download https://deno.land/std/examples/welcome.ts
 Warning Implicitly using master branch https://deno.land/std/examples/welcome.ts
 Compile https://deno.land/std/examples/welcome.ts
 Welcome to Deno 🦕
```

With your own file, use this command:

```shell
docker container run -it --rm -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome:with-deno-sample run helloworld.ts
Compile file:///usr/src/app/helloworld.ts
Download https://deno.land/std/fmt/colors.ts
Warning Implicitly using master branch https://deno.land/std/fmt/colors.ts
Hello world!
```

# How to use with Puppeteer

With tool like ["Puppeteer"](https://pptr.dev/#?product=Puppeteer&version=v1.15.0&show=api-class-browser), we can add a lot things with our Chrome Headless.

With some code in NodeJS, we can improve and make some tests.

See the [`with-puppeteer`](./with-puppeteer) folder for more details. We have to [follow the mapping of Chromium => Puppeteer described here](https://github.com/puppeteer/puppeteer/blob/main/versions.js).

If you have a NodeJS/Puppeteer script in your `src` folder named `pdf.js`, you can launch it using the following command:

```shell
docker container run -it --rm -v $(pwd)/src:/usr/src/app/src --cap-add=SYS_ADMIN ghcr.io/todd2982/alpine-chrome:with-puppeteer node src/pdf.js
```

With the ["font-wqy-zenhei"](https://pkgs.alpinelinux.org/package/edge/community/x86/font-wqy-zenhei) library, you could also manipulate asian pages like in [`with-puppeteer/test/screenshot-asia.js`](./with-puppeteer/test/screenshot-asia.js)

```shell
docker container run -it --rm -v $(pwd)/with-puppeteer/test:/usr/src/app/test --cap-add=SYS_ADMIN ghcr.io/todd2982/alpine-chrome:with-puppeteer node test/screenshot-asia.js
```

These websites are tested with the following supported languages:

- Chinese (with `https://m.baidu.com`)
- Japanese (with `https://www.yahoo.co.jp/`)
- Korean (with `https://www.naver.com/`)

# How to use with Puppeteer to test a Chrome Extension

[According to puppeteer official doc](https://github.com/puppeteer/puppeteer/blob/main/docs/api.md#working-with-chrome-extensions) you can not test a Chrome Extension in headless mode. You need a display available, that's where Xvfb comes in.

See the [`with-puppeteer-xvfb`](./with-puppeteer-xvfb) folder for more details. We have to [follow the mapping of Chromium => Puppeteer described here](https://github.com/puppeteer/puppeteer/blob/main/versions.js).

Assuming you have a NodeJS/Puppeteer script in your `src` folder named `extension.js`, and the [unpacked extension](./with-puppeteer-xvfb/test/chrome-extension/) in the `src/chrome-extension` folder, you can launch it using the following command:

```shell
docker container run -it --rm -v $(pwd)/src:/usr/src/app/src --cap-add=SYS_ADMIN ghcr.io/todd2982/alpine-chrome:with-puppeteer-xvfb node src/extension.js
```

The extension provided will change the page background in red for every website visited. This test `test/test.js` will load the extension and take a screenshot of the https://example.com website.

# How to use with Playwright

Like ["Puppeteer"](https://pptr.dev/#?product=Puppeteer&version=v6.0.0&show=api-class-browser), we can do a lot things using ["Playwright"](https://playwright.dev/docs/core-concepts/#browser) with our Chrome Headless.

Go to the [`with-playwright`](./with-playwright) folder and launch the following command:

```shell
docker container run -it --rm -v $(pwd)/test:/usr/src/app/test --cap-add=SYS_ADMIN ghcr.io/todd2982/alpine-chrome:with-playwright node test/test.js
```

An `example.png` file will be created in the [`with-playwright/test`](./with-playwright/test) folder.

# How to use with WebGL

By default, this image works with WebGL.

If you want to disable it, make sure to add `--disable-gpu` when launching Chromium.

`docker container run -it --rm --cap-add=SYS_ADMIN -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --screenshot --hide-scrollbars https://webglfundamentals.org/webgl/webgl-fundamentals.html`

`docker container run -it --rm --cap-add=SYS_ADMIN -v $(pwd):/usr/src/app ghcr.io/todd2982/alpine-chrome --screenshot --hide-scrollbars https://browserleaks.com/webgl`

# How to use with Chromedriver

[ChromeDriver](https://chromedriver.chromium.org/home) is a separate executable that Selenium WebDriver uses to control Chrome.
You can use this image as a base for your Docker based selenium tests. See [Guide for running Selenium tests using Chromedriver](https://www.browserstack.com/guide/run-selenium-tests-using-selenium-chromedriver).

# How to use with Selenoid

[Selenoid](https://github.com/aerokube/selenoid) is a powerful implementation of Selenium hub using Docker containers to launch browsers.
Even if it used to run browsers in docker containers, it can be quite useful as lightweight Selenium replacement.
`with-selenoid` image is a self sufficient selenium server, chrome and chromedriver installed.

You can run it with following command:

```shell
docker container run -it --rm --cap-add=SYS_ADMIN  -p 4444:4444 ghcr.io/todd2982/alpine-chrome:with-selenoid -capture-driver-logs
```

And run your tests against `http://localhost:4444/wd/hub`

One of the use-cases might be running automation tests in the environment with restricted Docker environment
like on some CI systems like GitLab CI, etc. In such case you may not have permissions for `--cap-add=SYS_ADMIN`
and you will need to pass the `--no-sandbox` to `chromedriver`.

See more [selenoid docs](https://aerokube.com/selenoid/latest/#_using_selenoid_without_docker)

# Run as root and override default entrypoint

We can run the container as root with this command:

```shell
docker container run --rm -it --entrypoint "" --user root ghcr.io/todd2982/alpine-chrome sh
```

# Run examples

Some examples are available on the `examples` [directory](examples):

- 🐳 [docker-compose](https://github.com/todd2982/alpine-chrome/tree/master/examples/docker-compose) to launch a chrome calling a nginx server in the same docker-compose
- ☸️ [kubernetes](https://github.com/todd2982/alpine-chrome/tree/master/examples/k8s) to launch a pod with a headless chrome
- 🖥 [x11](https://github.com/todd2982/alpine-chrome/blob/master/examples/x11) to experiment this image with a X11 server.

# References

- Headless Chrome website: https://developers.google.com/web/updates/2017/04/headless-chrome

- List of all options of the "Chromium" command line: https://peter.sh/experiments/chromium-command-line-switches/

- Where to file issues: https://github.com/todd2982/alpine-chrome/issues

- Maintained by: https://www.todd2982.com

# Versions (in latest)

## Alpine version

```shell
docker container run -it --rm --entrypoint "" ghcr.io/todd2982/alpine-chrome cat /etc/alpine-release
# 3.19.1
```

## Chrome version

```shell
docker container run -it --rm --entrypoint "" ghcr.io/todd2982/alpine-chrome chromium-browser --version
# Chromium 121.0.6167.85 Alpine Linux
```

## Image disk size

```shell
docker image inspect ghcr.io/todd2982/alpine-chrome --format='{{.Size}}'
# 663644797 # 633 MB
```