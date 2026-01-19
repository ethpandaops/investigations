<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';
	export let data;
</script>

<EvidenceDefaultLayout
	{data}
	logo="/notebooks/logo.png"
	builtWithEvidence={false}
>
	<slot slot="content" />
</EvidenceDefaultLayout>

<style>
	/* Make logo bigger and add title text */
	:global(header a[href="/notebooks/"] img) {
		height: 2rem !important;
	}
	:global(header a[href="/notebooks/"]) {
		display: flex !important;
		align-items: center !important;
		gap: 0.5rem !important;
	}
	:global(header a[href="/notebooks/"]::after) {
		content: "ethPandaOps";
		font-weight: 600;
		font-size: 1.1rem;
	}
</style>
