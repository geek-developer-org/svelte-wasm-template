# svelte-wasm-template
svelte(rollup) + wasm(rust) template

You need to ensure that the following commands can be executed:

```bash
cargo --version
rustup --version
npm --version
```

To compile WASM, the architecture ```wasm32-unknown-unknown``` is required. If it's not installed, you can do so with the following command:

```bash
rustup target add wasm32-unknown-unknown
```

To build, an additional tool called ```wasm-pack``` is needed. If it's not installed, you can install it with the following command:

```bash
cargo install wasm-pack
```

You can create a project using the following shell script:

```bash
create-svelte-wasm-project.sh svelte-wasm-normal
```

or

```bash
create-svelte-wasm-project.sh svelte-wasm-bundle bundle
```

Example of Execution:

```bash
cd svelte-wasm-bundle
npm install
wasm-pack build src/wasm-module --release --target web

npx rollup -c && npx http-server ./public
# or
npm run dev
```
