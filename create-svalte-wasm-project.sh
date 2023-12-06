#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Please specify directory."
  exit 1
fi

if [ -e $1 ] || [ -d $1 ]; then
  echo "Directory $1 exists."
  exit 1
fi

MODE="nomal"
if [ $# -gt 1 ] && [ $2 = "bundle" ]; then
  MODE="bundle"
elif [ $# -gt 1 ] && [ $2 != "normal" ]; then
  echo "Invalid mode (omission or \"normal\" or \"bundle\")."
  exit 1
fi

npx degit sveltejs/template $1
cd $1

node scripts/setupTypeScript.js

npm install rollup-plugin-css-asset --save-dev
npm install rollup-plugin-copy --save-dev
npm install rollup-plugin-clear --save-dev
if [ $MODE = "bundle" ]; then
  npm install @rollup/plugin-wasm --save-dev
fi

npx npm-check-updates -u
npm install

mkdir -p src/static/css
mkdir -p src/static/js
if [ $MODE != "bundle" ]; then
  mkdir -p src/static/wasm
fi
mv public/* src/static/
mv src/static/*.css src/static/css/

sed -i -e s/"en"/"ja"/g src/static/index.html
sed -i s/\\/global\\.css/\\.\\/css\\/global\\.css/g src/static/index.html
sed -i s/\\/build\\/bundle\\.css/\\.\\/css\\/bundle\\.css/g src/static/index.html
sed -i s/\\/build\\/bundle\\.js/\\.\\/js\\/bundle\\.js/g src/static/index.html
sed -i '/^$/d' src/static/index.html
sed -i s/^$'\t'// src/static/index.html

sed -i '/import css from '\''rollup-plugin-css-only'\'';/d' rollup.config.js
sed -i '0,/^$/ s/^$/import css from '\''rollup-plugin-css-asset'\'';\n/' rollup.config.js
sed -i '0,/^$/ s/^$/import copy from '\''rollup-plugin-copy'\'';\n/' rollup.config.js
sed -i  '0,/^$/ s/^$/import clear from '\''rollup-plugin-clear'\'';\n/' rollup.config.js
if [ $MODE = "bundle" ]; then
  sed -i  '0,/^$/ s/^$/import wasm from '\''@rollup\/plugin-wasm'\'';\n/' rollup.config.js
fi
sed -i '0,/sourcemap: true,/ s/sourcemap: true,/sourcemap: !production,/' rollup.config.js
if [ $MODE = "bundle" ]; then
  sed -i '0,/plugins: \[/ s/plugins: \[/plugins: \[\n\t\tcopy({\n\t\t\ttargets: \[\n\t\t\t\t{ src: '\''src\/static\/\*'\'', dest: '\''public'\'' }\n\t\t\t\]\n\t\t}),/' rollup.config.js
  sed -i '0,/plugins: \[/ s/plugins: \[/plugins: \[\n\t\twasm(),/' rollup.config.js
else
  sed -i '0,/plugins: \[/ s/plugins: \[/plugins: \[\n\t\tcopy({\n\t\t\ttargets: \[\n\t\t\t\t{ src: '\''src\/static\/\*'\'', dest: '\''public'\'' },\n\t\t\t\t{ src: '\''src\/wasm-module\/pkg\/*.wasm'\'', dest: '\''public\/wasm'\'' }\n\t\t\t\]\n\t\t}),/' rollup.config.js
fi
sed -i '0,/plugins: \[/ s/plugins: \[/plugins: \[\n\t\tclear({ targets: ['\''public'\''] }),/' rollup.config.js
sed -i '0,/file: '\''public\/build\/bundle.js'\''/ s/file: '\''public\/build\/bundle.js'\''/dir: '\''public'\'',\n\t\tentryFileNames: '\''js\/bundle.js'\'',\n\t\tassetFileNames: '\''css\/bundle.css'\''/' rollup.config.js
sed -i '0,/svelte({/ s/svelte({/svelte({\n\t\t\temitCss: true,/' rollup.config.js
sed -i '0,/css({ output: '\''bundle.css'\'' }),/ s/css({ output: '\''bundle.css'\'' }),/css({ name: '\''bundle'\'' }),/' rollup.config.js
sed -i '/^[\s\t]*\/\//d' rollup.config.js
# sed -i '/^$/d' rollup.config.js

mkdir -p src/wasm-module
cd src/wasm-module

cargo init --lib

cargo add wasm-bindgen
cargo add wee_alloc --optional

echo -e '\n[lib]\ncrate-type = ["cdylib"]'>>Cargo.toml
echo -e '\n[features]\ndefault = ["wee_alloc"]'>>Cargo.toml
echo -e '\n[package.metadata.wasm-pack.profile.release]\nwasm-opt = false'>>Cargo.toml
echo -e '\n[profile.release]\nopt-level = "s"\nlto = true\nstrip = true\ncodegen-units = 1\npanic = "abort"'>>Cargo.toml

echo -e 'use wasm_bindgen::prelude::wasm_bindgen;\n'>src/lib.rs
echo -e '#[cfg(feature = "wee_alloc")]\n#[global_allocator]\nstatic ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;\n'>>src/lib.rs
echo -e '#[wasm_bindgen]\npub fn message(input: &str) -> String {\n    format!("Hello,{}!!!", input).to_string()\n}'>>src/lib.rs

wasm-pack build --release --target web

cd ../../

echo -e '<script lang="ts">\n\texport let message: Function;\n\n\tlet input: string = "World";\n\tlet output: string;\n\n\t$: output = message(input);\n</script>\n'>src/App.svelte
echo -e '<main>\n\t<div>\n\t\t<input type="text" bind:value={input} />\n\t</div>\n\t<div>\n\t\t<div>{output}</div>\n\t</div>\n</main>\n\n<style>\n\tinput:focus {\n\t\toutline: none;\n\t}\n</style>'>>src/App.svelte

echo -e "import App from './App.svelte';\nimport init, { message } from './wasm-module/pkg';">src/main.ts
if [ $MODE = "bundle" ]; then
  echo -e "import wasm from './wasm-module/pkg/wasm_module_bg.wasm';">>src/main.ts
fi
echo -e "\nconst app = (async () => {">>src/main.ts
if [ $MODE = "bundle" ]; then
  echo -e "\t// @ts-ignore\n\tawait init(await wasm());\n">>src/main.ts
else
  echo -e "\tawait init('./wasm/wasm_module_bg.wasm');\n">>src/main.ts
fi
echo -e "\tconst app = new App({\n\t\ttarget: document.body,\n\t\tprops: {\n\t\t\tmessage\n\t\t}\n\t});\n})();\n\nexport default app;">>src/main.ts

echo -e 'html,body{margin:0;padding:0;box-sizing:border-box;}'>src/static/css/global.css

# npx rollup -c
# npx http-server ./public

echo "Success!!!"
echo "Next Step"
echo "cd $1"
echo "npx rollup -c && npx http-server ./public"
echo "or"
echo "npm run dev"
