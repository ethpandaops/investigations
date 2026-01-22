<script>
    import { base } from '$app/paths';
    export let source = '';
    export let query = '';

    let sqlContent = '';
    let expanded = false;

    // Fetch the SQL file from the static folder
    async function loadSql() {
        try {
            const response = await fetch(`${base}/sql/${source}/${query}.sql`);
            if (response.ok) {
                sqlContent = await response.text();
            } else {
                sqlContent = `-- Could not load query: ${source}/${query}.sql`;
            }
        } catch (e) {
            sqlContent = `-- Error loading query: ${e.message}`;
        }
    }

    $: if (source && query) {
        loadSql();
    }
</script>

<details class="sql-source" bind:open={expanded}>
    <summary>
        <span class="toggle-icon">{expanded ? '▼' : '▶'}</span>
        View Query: {query}
    </summary>
    <pre class="sql-code"><code>{sqlContent}</code></pre>
</details>

<style>
    .sql-source {
        margin: 0.5rem 0 1rem 0;
        border: 1px solid #e0e0e0;
        border-radius: 4px;
        font-size: 0.875rem;
    }

    summary {
        padding: 0.5rem 0.75rem;
        cursor: pointer;
        background: #f5f5f5;
        color: #5c5650;
        font-family: monospace;
        list-style: none;
    }

    summary::-webkit-details-marker {
        display: none;
    }

    .toggle-icon {
        margin-right: 0.5rem;
        font-size: 0.75rem;
    }

    .sql-code {
        margin: 0;
        padding: 1rem;
        background: #fafafa;
        overflow-x: auto;
        font-size: 0.8125rem;
        line-height: 1.5;
    }

    code {
        font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
        color: #3d3a2a;
    }

    /* Dark mode */
    :global([data-theme="dark"]) .sql-source {
        border-color: #3d3a2a;
    }

    :global([data-theme="dark"]) summary {
        background: #2a2725;
        color: #9a958d;
    }

    :global([data-theme="dark"]) .sql-code {
        background: #1a1918;
    }

    :global([data-theme="dark"]) code {
        color: #c5c2ba;
    }
</style>
