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
canvas.id = "canvas"
canvas.width = 640
canvas.height = 480

import {WEB_SOCKET_PORT, THEME_JSON_WEBPATH, CODE_WEBPATH, LANG_WEBPATH} from "./constants.js"

const root = /** @type {HTMLElement} */ (document.getElementById("root"))
const loading_indicator = /** @type {HTMLElement} */ (document.getElementById("loading_indicator"))

let code_promise = fetchCode()
let theme_promise = fetchTheme()
let lang_promise = fetchLang()
const wasm_promise = shikiji_wasm.getWasmInlined()

const socket = new WebSocket("ws://localhost:" + WEB_SOCKET_PORT)

socket.addEventListener("message", event => {
	switch (event.data) {
		case THEME_JSON_WEBPATH:
			theme_promise = fetchTheme()
			update()
			break
		case CODE_WEBPATH:
			code_promise = fetchCode()
			update()
			break
		case LANG_WEBPATH:
			lang_promise = fetchLang()
			update()
			break
	}
})

update()

/** @returns {Promise<string>} */
function fetchCode() {
	return fetch(CODE_WEBPATH).then(res => res.text())
}
/** @returns {Promise<shikiji.ThemeRegistration>} */
function fetchTheme() {
	return fetch(THEME_JSON_WEBPATH).then(res => res.json())
}
/** @returns {Promise<shikiji.LanguageRegistration>} */
function fetchLang() {
	return fetch(LANG_WEBPATH).then(res => res.json())
}

async function update() {
	const highlighter_promise = shikiji.getHighlighterCore({
		themes: [theme_promise],
		langs: [lang_promise],
		loadWasm: () => wasm_promise,
	})

	loading_indicator.style.display = "block"
	const [code, theme, lang, highlighter] = await Promise.all([
		code_promise,
		theme_promise,
		lang_promise,
		highlighter_promise,
	])
	loading_indicator.style.display = "none"

	const tokens_lines = highlighter.codeToThemedTokens(code, {
		lang: lang.name,
		theme: theme.name,
	})

	/** @type {HTMLElement[]} */
	const elements_lines = new Array(tokens_lines.length)
	/** @type {Map<HTMLElement, string>} */
	const scopes_map = new Map()

	for (let i = 0; i < tokens_lines.length; i += 1) {
		const tokens = tokens_lines[i]
		/** @type {HTMLElement[]} */
		const elements = new Array(tokens.length)

		for (let j = 0; j < tokens.length; j += 1) {
			const token = tokens[j]
			if (!token.explanation) continue

			const token_el = document.createElement("span")
			token_el.className = "token"
			elements[j] = token_el

			for (const explanation of token.explanation) {
				const scope_el = document.createElement("span")
				scope_el.className = "scope"
				token_el.append(scope_el)

				scope_el.style.color = token.color || ""
				scope_el.textContent = explanation.content

				if (token.fontStyle) {
					if (token.fontStyle & shikiji.FontStyle.Italic) {
						scope_el.style.fontStyle = "italic"
					}
					if (token.fontStyle & shikiji.FontStyle.Bold) {
						scope_el.style.fontWeight = "bold"
					}
					if (token.fontStyle & shikiji.FontStyle.Underline) {
						scope_el.style.textDecoration = "underline"
					}
				}

				/*
				Skip first because it's always the root scope
				*/
				let scope = ""
				for (let i = 1; i < explanation.scopes.length; i += 1) {
					let name = explanation.scopes[i].scopeName
					if (name.endsWith(".odin")) {
						name = name.slice(0, -5)
					}
					scope += name + "\n"
				}

				scopes_map.set(scope_el, scope)
			}
		}

		const line = document.createElement("div")
		line.className = "line"
		elements_lines[i] = line
		line.append(...elements)
	}

	const shiki_el = document.createElement("div")
	shiki_el.className = "shiki"
	shiki_el.append(...elements_lines)
	root.innerHTML = ""
	root.append(shiki_el)

	/*
	Show hovered token scope
	*/
	const tooltip_el = document.createElement("div")
	tooltip_el.className = "scope-tooltip"
	root.append(tooltip_el)

	/** @type {HTMLElement | null} */
	let last_scope_el = null
	shiki_el.addEventListener("mousemove", e => {
		const target = e.target
		if (!(target instanceof HTMLElement)) {
			tooltip_el.style.visibility = "hidden"
			last_scope_el = null
			return
		}

		if (target !== last_scope_el) {
			const scope = scopes_map.get(target)
			if (!scope) {
				tooltip_el.style.visibility = "hidden"
				last_scope_el = null
				return
			}

			last_scope_el = target
			tooltip_el.textContent = scope
			tooltip_el.style.visibility = "visible"
		}

		tooltip_el.style.transform = `translate(${e.clientX}px, ${e.clientY}px)`
	})

	shiki_el.addEventListener("mouseleave", () => {
		tooltip_el.style.visibility = "hidden"
		last_scope_el = null
	})
}
