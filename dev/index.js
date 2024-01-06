import * as wasm from "../wasm/runtime.js"

if (import.meta.env.DEV) {
	wasm.env.enableConsole()
}

const div = document.createElement("div")
div.innerText = "Loading..."
div.id = "lol"
void document.body.appendChild(div)
div.addEventListener("lol", () => {
	console.log("lol")
})

document.body.style.minHeight = "200vh"

const wasm_path = "dist/lib.wasm"
const instance = wasm.zeroWasmInstance()

const response = await fetch(wasm_path)
const file = await response.arrayBuffer()
const source_instance = await WebAssembly.instantiate(file, {
	env: {}, // TODO
	odin_env: wasm.env.makeOdinEnv(instance),
	odin_ls: wasm.ls.makeOdinLS(instance),
	odin_dom: wasm.dom.makeOdinDOM(instance),
})
wasm.initWasmInstance(instance, source_instance.instance.exports)

console.log("Exports", instance.exports)
console.log("Memory", instance.memory)

instance.exports._start()
instance.exports._end()

const canvas = document.createElement("canvas")
canvas.width = 640
canvas.height = 480
const ctx = canvas.getContext("webgl")
if (!ctx) throw new Error("Could not get WebGL context")
document.body.appendChild(canvas)
