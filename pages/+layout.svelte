<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';
	import { base } from '$app/paths';
	export let data;

	/**
	 * Recursively filter out pages with hidden: true in frontMatter
	 * @param {Object} node - The page manifest node
	 * @returns {Object} - Filtered node
	 */
	function filterHiddenPages(node) {
		if (!node) return node;
		const filteredChildren = {};
		for (const [key, child] of Object.entries(node.children || {})) {
			if (child.frontMatter?.hidden === true) {
				continue;
			}
			filteredChildren[key] = filterHiddenPages(child);
		}
		return { ...node, children: filteredChildren };
	}

	// Filter hidden pages from the manifest
	$: filteredData = data.pagesManifest
		? { ...data, pagesManifest: filterHiddenPages(data.pagesManifest) }
		: data;
</script>

<EvidenceDefaultLayout
	data={filteredData}
	logo="{base}/panda.png"
	builtWithEvidence={false}
	maxWidth={1600}
>
	<slot slot="content" />
</EvidenceDefaultLayout>

<style>
	/* ========== HEADER: NOIR DETECTIVE AGENCY ========== */

	/* Header container - the agency entrance */
	:global(header) {
		background:
			/* Subtle film grain texture */
			url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E"),
			linear-gradient(180deg, #f8f7f3 0%, #f4f2eb 100%) !important;
		background-blend-mode: overlay, normal !important;
		border-bottom: none !important;
		padding: 1rem 0 !important;
		min-height: 5rem !important;
		z-index: 50 !important;
		box-shadow:
			0 1px 0 #e8e5dc,
			0 4px 12px -4px rgba(61, 58, 42, 0.08) !important;
	}

	/* Terracotta accent line - case file edge */
	:global(header::after) {
		content: "" !important;
		position: absolute !important;
		bottom: 0 !important;
		left: 0 !important;
		width: 100% !important;
		height: 3px !important;
		background: linear-gradient(
			90deg,
			#bb5a38 0%,
			#bb5a38 30%,
			#d4a090 50%,
			transparent 100%
		) !important;
	}

	/* Space between header and content */
	:global(header + div),
	:global(header + main),
	:global(body > div > div:nth-child(2)) {
		margin-top: 1.5rem !important;
	}

	/* Vertical alignment - sidebar and main content */
	:global(div.flex.flex-row) {
		align-items: flex-start !important;
	}

	/* Main content area alignment */
	:global(main) {
		padding-top: 0 !important;
	}

	/* Logo link container - the agency sign */
	:global(header a[href="/"]) {
		display: flex !important;
		align-items: center !important;
		gap: 1rem !important;
		text-decoration: none !important;
		position: relative !important;
	}

	/* Detective panda - THE HERO */
	:global(header a[href="/"] img) {
		height: 3.5rem !important;
		width: auto !important;
		filter: drop-shadow(2px 3px 4px rgba(61, 58, 42, 0.2)) !important;
		transition: transform 0.2s ease-out, filter 0.2s ease-out !important;
	}

	:global(header a[href="/"]:hover img) {
		transform: scale(1.03) !important;
		filter: drop-shadow(3px 4px 6px rgba(61, 58, 42, 0.25)) !important;
	}

	/* INVESTIGATIONS - etched glass typography */
	:global(header a[href="/"]::after) {
		content: "INVESTIGATIONS" !important;
		font-family: "Courier New", Courier, monospace !important;
		font-weight: 700 !important;
		font-size: 1.4rem !important;
		letter-spacing: 0.22em !important;
		text-transform: uppercase !important;
		color: #3d3a2a !important;
		position: relative !important;
		padding-bottom: 0.4rem !important;
		/* Subtle text shadow for etched effect */
		text-shadow:
			1px 1px 0 rgba(255,255,255,0.8),
			-0.5px -0.5px 0 rgba(61, 58, 42, 0.1) !important;
	}

	/* ethPandaOps credit - subtle agency watermark */
	:global(header a[href="/"]::before) {
		content: "ethPandaOps" !important;
		font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace !important;
		font-weight: 500 !important;
		font-size: 0.6rem !important;
		letter-spacing: 0.12em !important;
		text-transform: uppercase !important;
		color: #9a958d !important;
		position: absolute !important;
		left: 4.5rem !important;
		bottom: -0.1rem !important;
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
		padding-top: 1.5rem !important;
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

	/* ========== DARK MODE ========== */

	/* Header - dark background */
	:global([data-theme="dark"] header) {
		background:
			url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E"),
			linear-gradient(180deg, #1a1918 0%, #141312 100%) !important;
		box-shadow:
			0 1px 0 #2a2725,
			0 4px 12px -4px rgba(0, 0, 0, 0.3) !important;
	}

	/* Header text - light for dark mode */
	:global([data-theme="dark"] header a[href="/"]::after) {
		color: #e8e5dc !important;
		text-shadow:
			1px 1px 0 rgba(0,0,0,0.5),
			-0.5px -0.5px 0 rgba(255, 255, 255, 0.05) !important;
	}

	:global([data-theme="dark"] header a[href="/"]::before) {
		color: #6b6560 !important;
	}

	/* Sidebar - dark mode */
	:global([data-theme="dark"] aside.w-48) {
		border-left-color: #bb5a38 !important;
	}

	:global([data-theme="dark"] aside .font-semibold) {
		color: #6b6560 !important;
	}

	:global([data-theme="dark"] aside a.font-semibold:hover),
	:global([data-theme="dark"] aside span.font-semibold:hover) {
		color: #9a958d !important;
	}

	:global([data-theme="dark"] aside a.py-1:not(.font-semibold)),
	:global([data-theme="dark"] aside span.py-1:not(.font-semibold)) {
		color: #9a958d !important;
	}

	:global([data-theme="dark"] aside a.py-1:not(.font-semibold):hover) {
		color: #e8e5dc !important;
		background: linear-gradient(90deg, rgba(187, 90, 56, 0.15) 0%, transparent 100%) !important;
	}

	:global([data-theme="dark"] aside .text-primary) {
		color: #d4a090 !important;
		background: linear-gradient(90deg, rgba(187, 90, 56, 0.2) 0%, transparent 100%) !important;
	}

	:global([data-theme="dark"] aside .text-base-content-muted) {
		color: #9a958d !important;
	}

	:global([data-theme="dark"] aside .text-base-content-muted:hover) {
		color: #e8e5dc !important;
	}

	:global([data-theme="dark"] aside > div > div:first-child .font-semibold) {
		color: #e8e5dc !important;
	}

	:global([data-theme="dark"] aside > div > div.pb-6:not(:first-child)::before) {
		background: #2a2725 !important;
	}

	/* Landing page cards - dark mode */
	:global([data-theme="dark"] article a[href*="/2026-"]) {
		background: linear-gradient(135deg, rgba(30, 28, 26, 0.9) 0%, rgba(26, 25, 24, 1) 100%) !important;
		border-left-color: #bb5a38 !important;
	}

	:global([data-theme="dark"] article a[href*="/2026-"] > div:first-child) {
		color: #bb5a38 !important;
	}

	:global([data-theme="dark"] article a[href*="/2026-"] > div:nth-child(2)) {
		color: #e8e5dc !important;
	}

	:global([data-theme="dark"] article a[href*="/2026-"] > div:nth-child(3)) {
		color: #9a958d !important;
	}

	/* Landing page hero text - dark mode */
	:global([data-theme="dark"] article > div > div > div:first-child) {
		color: #e8e5dc !important;
		text-shadow: 1px 1px 0 rgba(0,0,0,0.5) !important;
	}

	:global([data-theme="dark"] article > div > div > p) {
		color: #9a958d !important;
	}

	:global([data-theme="dark"] article > div > div > p a) {
		color: #d4a090 !important;
	}

	/* Footer - dark mode */
	:global([data-theme="dark"] article > div:last-child) {
		border-top-color: #2a2725 !important;
		color: #6b6560 !important;
	}

	:global([data-theme="dark"] article > div:last-child a) {
		color: #9a958d !important;
		border-bottom-color: #3d3a2a !important;
	}

	/* Main content text - dark mode contrast fixes */
	:global([data-theme="dark"] article) {
		color: #c5c2ba !important;
	}

	:global([data-theme="dark"] article strong),
	:global([data-theme="dark"] article b),
	:global([data-theme="dark"] .markdown strong),
	:global([data-theme="dark"] .markdown b) {
		color: #e8e5dc !important;
	}

	:global([data-theme="dark"] article h1),
	:global([data-theme="dark"] article h2),
	:global([data-theme="dark"] article h3),
	:global([data-theme="dark"] article h4),
	:global([data-theme="dark"] .markdown h1),
	:global([data-theme="dark"] .markdown h2),
	:global([data-theme="dark"] .markdown h3),
	:global([data-theme="dark"] .markdown h4) {
		color: #e8e5dc !important;
	}

	:global([data-theme="dark"] article code),
	:global([data-theme="dark"] .markdown code) {
		background: #2a2725 !important;
		border-color: #3d3a2a !important;
		color: #d4a090 !important;
	}

	:global([data-theme="dark"] article a),
	:global([data-theme="dark"] .markdown a) {
		color: #d4a090 !important;
	}
</style>
