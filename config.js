export const IS_DEV = /** @type {boolean} */ (false)

/*
^^^ Don't touch the first line of this file :) ^^^
*/

export const IS_PROD = /** @type {boolean} */ (!IS_DEV)

export const HTTP_PORT = 3000
export const WEB_SOCKET_PORT = 8080

export const PLAYGROUND_DIRNAME = "example"
export const DIST_DIRNAME = "dist"
export const PACKAGE_DIRNAME = "wasm"

export const CONFIG_FILENAME = "config.js"

export const WASM_FILENAME = "main.wasm"
export const WASM_PATH = PLAYGROUND_DIRNAME + "/" + WASM_FILENAME

export const MESSAGE_RELOAD = "reload"
