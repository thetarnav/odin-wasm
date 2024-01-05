import {defineConfig} from 'vite'

export default defineConfig({
    server: {
        port: 3000,
        host: true,
        hmr: false,
    },
    plugins: [],
    // test: {
    //     watch: false,
    //     environment: 'node',
    //     isolate: false,
    //     setupFiles: 'vitest.setup.ts',
    // },
})
