<script lang="ts">
	export let message: Function;

	let input: string = "World";
	let output: string;

	$: output = message(input);
</script>

<main>
	<div>
		<input type="text" bind:value={input} />
	</div>
	<div>
		<div>{output}</div>
	</div>
</main>

<style>
	input:focus {
		outline: none;
	}
</style>
