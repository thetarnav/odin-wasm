export let CONSOLE_ENABLED = false
/** @returns {void} */
export function enableConsole() {
	CONSOLE_ENABLED = true
}

/**
 * @param   {boolean} [condition]
 * @param   {...any}  data
 * @returns {void}
 */
export function assert(condition, ...data) {
	if (!CONSOLE_ENABLED) return
	// eslint-disable-next-line no-console
	console.assert(condition, ...data)
}
/**
 * @param   {...any} data
 * @returns {void}
 */
export function log(...data) {
	if (!CONSOLE_ENABLED) return
	// eslint-disable-next-line no-console
	console.log(...data)
}
/**
 * @param   {...any} data
 * @returns {void}
 */
export function warn(...data) {
	if (!CONSOLE_ENABLED) return
	// eslint-disable-next-line no-console
	console.warn(...data)
}
/**
 * @param   {...any} data
 * @returns {void}
 */
export function error(...data) {
	if (!CONSOLE_ENABLED) return
	// eslint-disable-next-line no-console
	console.error(...data)
}
