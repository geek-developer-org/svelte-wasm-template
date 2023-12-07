import { spawn } from 'child_process';
import svelte from 'rollup-plugin-svelte';
import commonjs from '@rollup/plugin-commonjs';
import resolve from '@rollup/plugin-node-resolve';
import livereload from 'rollup-plugin-livereload';
import sveltePreprocess from 'svelte-preprocess';
import esbuild from 'rollup-plugin-esbuild';
import css from 'rollup-plugin-css-asset';
import copy from 'rollup-plugin-copy';
import clear from 'rollup-plugin-clear';

const production = !process.env.ROLLUP_WATCH;

function serve() {
	let server;

	function toExit() {
		if (server) server.kill(0);
	}

	return {
		writeBundle() {
			if (server) return;
			server = spawn('npm', ['run', 'start', '--', '--dev'], {
				stdio: ['ignore', 'inherit', 'inherit'],
				shell: true
			});

			process.on('SIGTERM', toExit);
			process.on('exit', toExit);
		}
	};
}

export default {
	input: 'src/main.ts',
	output: {
		sourcemap: !production,
		format: 'iife',
		name: 'app',
		dir: 'public',
		entryFileNames: 'js/bundle.js',
		assetFileNames: 'css/bundle.css'
	},
	plugins: [
		production && clear({ targets: ['public'] }),
		copy({
			targets: [
				{ src: 'src/static/*', dest: 'public' },
				{ src: 'src/wasm-module/pkg/*.wasm', dest: 'public/wasm' }
			]
		}),
		svelte({
			emitCss: true,
			preprocess: sveltePreprocess({ sourceMap: !production }),
			compilerOptions: {
				dev: !production
			}
		}),
		css({ name: 'bundle' }),

		resolve({
			browser: true,
			dedupe: ['svelte'],
			exportConditions: ['svelte']
		}),
		commonjs(),
		esbuild({
			sourceMap: !production,
			minify: production
		}),

		!production && serve(),

		!production && livereload('public'),

	],
	watch: {
		clearScreen: false
	}
};
