import App from './App.svelte';
import init, { message } from './wasm-module/pkg';

const app = (async () => {
	await init('./wasm/wasm_module_bg.wasm');

	const app = new App({
		target: document.body,
		props: {
			message
		}
	});
})();

export default app;
