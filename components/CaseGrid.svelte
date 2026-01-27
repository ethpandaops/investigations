<script>
	import { investigations } from '$lib/investigationsStore.js';

	const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

	function formatDate(dateStr) {
		if (!dateStr) return '';
		try {
			const d = new Date(dateStr);
			return `${MONTHS[d.getUTCMonth()]} ${d.getUTCDate()}`;
		} catch (e) {
			return String(dateStr);
		}
	}

	function cardClass(index) {
		if (index === 0) return 'case-card case-card-latest';
		if (index === 1) return 'case-card case-card-secondary';
		return 'case-card case-card-tertiary';
	}
</script>

{#if $investigations.length > 0}
<div class="case-grid">
	{#each $investigations.slice(0, 4) as inv, i}
		<a href={inv.href} class={cardClass(i)}>
			<div class="case-card-date {i === 0 ? 'case-card-date-latest' : 'case-card-date-default'}">
				{i === 0 ? 'Latest Case' : formatDate(inv.date)}
			</div>
			<div class="case-card-title">{inv.title}</div>
			<div class="case-card-desc">{inv.description}</div>
		</a>
	{/each}
</div>
{/if}

<style>
	.case-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1.25rem;
	}

	.case-card {
		display: block;
		padding: 1.5rem 1.75rem;
		text-decoration: none;
		transition: all 0.15s ease-out;
	}

	.case-card-latest {
		background: linear-gradient(135deg, rgba(248,247,243,0.9) 0%, rgba(244,242,235,1) 100%);
		border-left: 4px solid #bb5a38;
		box-shadow: 0 2px 8px -2px rgba(61,58,42,0.08);
	}

	.case-card-secondary {
		background: rgba(248,247,243,0.7);
		border-left: 4px solid #d4a090;
	}

	.case-card-tertiary {
		background: rgba(248,247,243,0.5);
		border-left: 4px solid #ddd9d1;
	}

	.case-card-date {
		font-family: ui-monospace, monospace;
		font-size: 0.6rem;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		margin-bottom: 0.5rem;
	}

	.case-card-date-latest {
		color: #bb5a38;
		font-weight: 600;
	}

	.case-card-date-default {
		color: #9a958d;
	}

	.case-card-title {
		color: #3d3a2a;
		font-weight: 700;
		font-size: 1.1rem;
		margin-bottom: 0.4rem;
	}

	.case-card-desc {
		font-size: 0.85rem;
		color: #6b6560;
		line-height: 1.5;
	}

	/* Dark mode */
	:global([data-theme="dark"]) .case-card {
		background: linear-gradient(135deg, rgba(30, 28, 26, 0.9) 0%, rgba(26, 25, 24, 1) 100%) !important;
		border-left-color: #bb5a38 !important;
	}

	:global([data-theme="dark"]) .case-card-date {
		color: #bb5a38 !important;
	}

	:global([data-theme="dark"]) .case-card-title {
		color: #e8e5dc !important;
	}

	:global([data-theme="dark"]) .case-card-desc {
		color: #9a958d !important;
	}

	/* Mobile responsive */
	@media (max-width: 640px) {
		.case-grid {
			grid-template-columns: 1fr;
		}

		.case-card {
			padding: 1.25rem 1.25rem;
		}
	}
</style>
