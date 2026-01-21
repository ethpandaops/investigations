<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';
	import { base } from '$app/paths';
	export let data;
</script>

<EvidenceDefaultLayout
	{data}
	logo="{base}/logo.png"
	builtWithEvidence={false}
	maxWidth={1600}
>
	<slot slot="content" />
</EvidenceDefaultLayout>

<style>
	/* Make logo bigger and add title text */
	:global(header a[href="/investigations/"] img) {
		height: 2rem !important;
	}
	:global(header a[href="/investigations/"]) {
		display: flex !important;
		align-items: center !important;
		gap: 0.5rem !important;
	}
	:global(header a[href="/investigations/"]::after) {
		content: "ethPandaOps";
		font-weight: 600;
		font-size: 1.1rem;
	}
	/* Hide SQL query UI buttons */
	:global(button[aria-label="show-sql"]),
	:global(button[aria-label="view-query"]),
	:global(.svelte-1granpn) {
		display: none !important;
	}

	/* Hide breadcrumbs */
	:global(main > div.print\:hidden:first-child) {
		display: none !important;
	}

	/* Center chart titles */
	:global(.chart-title) {
		text-align: center !important;
	}

	/* ========== SIDEBAR: EDITORIAL JOURNAL AESTHETIC ========== */

	/* Sidebar container - wider with left border accent */
	:global(aside.w-48) {
		width: 15rem !important;
		border-left: 3px solid #bb5a38 !important;
		margin-left: 0 !important;
		padding-left: 0 !important;
	}
	:global(aside.w-48 > div.w-48) {
		width: 15rem !important;
		padding-left: 1.25rem !important;
	}

	/* Section containers - generous spacing */
	:global(aside .pb-6) {
		padding-bottom: 1.75rem !important;
		margin-bottom: 0 !important;
	}

	/* Section headers - chapter markers */
	:global(aside .font-semibold) {
		font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace !important;
		font-weight: 500 !important;
		font-size: 0.65rem !important;
		letter-spacing: 0.15em !important;
		text-transform: uppercase !important;
		color: #9a958d !important;
		margin-top: 0 !important;
		margin-bottom: 0.75rem !important;
		padding: 0 !important;
		border: none !important;
		display: flex !important;
		align-items: center !important;
		gap: 0.5rem !important;
	}
	:global(aside .font-semibold::before) {
		content: "" !important;
		display: inline-block !important;
		width: 6px !important;
		height: 6px !important;
		background: #bb5a38 !important;
		border-radius: 1px !important;
		flex-shrink: 0 !important;
	}

	/* Remove underline on section header hover */
	:global(aside a.font-semibold:hover),
	:global(aside span.font-semibold:hover) {
		text-decoration: none !important;
		color: #6b6560 !important;
	}

	/* Navigation links - refined and spacious */
	:global(aside a.py-1:not(.font-semibold)),
	:global(aside span.py-1:not(.font-semibold)) {
		display: block !important;
		padding: 0.5rem 0 0.5rem 1rem !important;
		margin-left: -0.5rem !important;
		font-size: 0.875rem !important;
		font-weight: 400 !important;
		line-height: 1.5 !important;
		color: #5c5650 !important;
		border-left: 2px solid transparent !important;
		transition: all 0.15s ease-out !important;
		text-decoration: none !important;
	}

	/* Link hover state - terracotta slide-in */
	:global(aside a.py-1:not(.font-semibold):hover) {
		color: #3d3a2a !important;
		border-left-color: #d4a090 !important;
		background: linear-gradient(90deg, rgba(187, 90, 56, 0.06) 0%, transparent 100%) !important;
		text-decoration: none !important;
	}

	/* Active link - bold terracotta accent */
	:global(aside .text-primary) {
		color: #bb5a38 !important;
		font-weight: 600 !important;
		border-left-color: #bb5a38 !important;
		background: linear-gradient(90deg, rgba(187, 90, 56, 0.1) 0%, transparent 100%) !important;
	}

	/* Muted text override for inactive links */
	:global(aside .text-base-content-muted) {
		color: #5c5650 !important;
	}
	:global(aside .text-base-content-muted:hover) {
		color: #3d3a2a !important;
	}

	/* First section (Home) - special treatment */
	:global(aside > div > div:first-child .font-semibold) {
		font-size: 0.7rem !important;
		color: #3d3a2a !important;
		font-weight: 600 !important;
	}
	:global(aside > div > div:first-child .font-semibold::before) {
		width: 8px !important;
		height: 8px !important;
		border-radius: 50% !important;
	}

	/* Subtle separator between major sections */
	:global(aside > div > div.pb-6:not(:first-child)::before) {
		content: "" !important;
		display: block !important;
		width: 2rem !important;
		height: 1px !important;
		background: #ddd9d1 !important;
		margin-bottom: 1.25rem !important;
		margin-left: 0.75rem !important;
	}
</style>
