import App from './App.svelte';
import init, { message } from './wasm-module/pkg';
import wasm from './wasm-module/pkg/wasm_module_bg.wasm';

const app = (async () => {
	// @ts-ignore
	await init(await wasm());

	const app = new App({
		target: document.body,
		props: {
			message
		}
	});
})();

export default app;
