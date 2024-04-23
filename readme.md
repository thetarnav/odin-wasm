# Odin WASM

**For using Odin and WASM together.**

[![demo gif](https://raw.githubusercontent.com/thetarnav/odin-wasm/main/assets/camera.gif)](https://thetarnav.github.io/odin-wasm/#camera)

## What is this?

### 1. A library of WASM bindings

[A library of wasm bindings](https://github.com/thetarnav/odin-wasm/tree/main/wasm) from [`Odin/vendor/wasm`](https://github.com/odin-lang/Odin/tree/master/vendor/wasm) implemented using modern JavaScript with ES modules and JSDoc.

The implementation is mostly the same as the original, here are the differences:

- ESM - it was written to be used in a modern JS environment, assuming that the user will use a bundler like [Webpack](https://webpack.js.org/) or [Rollup](https://rollupjs.org/) to bundle the code, and tree-shake the unused parts.
- JSDoc - the original bindings are not documented, so I added JSDoc to the bindings to make it easier to use them.
- [Improvements to getting window position and size](https://github.com/thetarnav/odin-wasm/commit/abd015822d0667ae7ebec7c0b7d4508a489b9c44#diff-70784127da28e4d9d43c91e03af22f56c23f45ec12af76e4deed68c37f7776e4)

### 2. Odin + WASM example

[thetarnav.github.io/odin-wasm](https://thetarnav.github.io/odin-wasm)

In [`example/`](https://github.com/thetarnav/odin-wasm/tree/main/example) you can find an example of how to use Odin and WASM together. Mainly focused on WebGL as I'm going through the [WebGL Fundamentals](https://webgl2fundamentals.org/) tutorial.

### 3. A template repo

Feel free to use this repo as a template for your own projects.

There are some convenience scripts in [`main.js`](https://github.com/thetarnav/odin-wasm/tree/main/main.js) for building and running the example. And a github action for building and deploying the example to github pages.

## Development

### Dependencies

- [Odin](https://odin-lang.org/docs/install/) (and [LLVM](https://apt.llvm.org/))
- [Node 20](https://nodejs.org/)
- [Chrome Devtools Support](https://chromewebstore.google.com/detail/cc++-devtools-support-dwa/pdcpmagijalfljmkmjngeonclgbbannb): for debugging *(optional)*

### OLS

Add `js_wasm32` target to `ols.json` if you want to use [OLS](https://github.com/DanielGavin/ols):

```json
{
    "checker_args": "-target:js_wasm32 -vet-unused -vet-shadowing -vet-style -vet-semicolon",
    "enable_format": false
}
```

### Scripts

Take look at [`package.json`](https://github.com/thetarnav/odin-wasm/tree/main/package.json) for all the available scripts.

*(You need to run `npm i` beforehand)*

The most important ones are:

- `npm run dev` - starts the server and watches for changes
- `npm run build` - builds the example to `dist/`
- `npm run preview` - starts a server to preview the built example