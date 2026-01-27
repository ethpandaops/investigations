## Creating new pages

- Do not repeat the header in the page. It's already in the layout.
- Investigations MUST use a fixed time range for the data so that the analysis is reproducible.

## Page Frontmatter Schema

All pages should include metadata in the frontmatter. Here's the standard schema:

```yaml
---
title: Page Title
sidebar_position: 1
description: Brief description of the page
date: 2025-01-20T14:30:00Z
author: samcm
tags:
  - tag1
  - tag2
---
```

### Required Fields

- `title`: The page title (displayed in browser tab and navigation)
- `description`: Brief description for SEO and social sharing previews (not displayed on page - the Question section serves as the visible hook)

### Optional Fields

- `sidebar_position`: Order in the sidebar navigation (lower = higher)
- `date`: Publication datetime in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ). Pages are sorted by this datetime descending.
- `author`: Author username (see supported authors below)
- `tags`: Array of relevant tags for categorization

### Supported Authors

Use these usernames for the `author` field to show profile pictures:

| Username | Name |
|----------|------|
| `samcm` | Sam Calder-Mason |
| `parithosh` | Parithosh Jayanthi |
| `pk910` | pk910 |
| `savid` | Andrew Davis |
| `skylenet` | Rafael Matias |
| `mattevans` | Matty Evans |
| `qu0b` | Stefan |
| `barnabasbusa` | Barnabas Busa |
| `ethpandaops` | ethPandaOps (team) |

## Displaying Page Metadata

Use the `PageMeta` component to display metadata. For investigations, also include `networks` and time range:

```svelte
<script>
    import PageMeta from '$lib/PageMeta.svelte';
</script>

<PageMeta
    date="2025-01-20T14:30:00Z"
    author="samcm"
    tags={["tag1", "tag2"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-01-14T00:00:00Z"
    endTime="2025-01-20T23:59:59Z"
/>
```

Note: The `description` prop exists for backwards compatibility but is not displayed. The Question section serves as the visual description.

## SQL Queries

**Important**: SQL code blocks must be at the top level of the markdown file, not wrapped in HTML elements like `<div>`. Evidence's preprocessor won't process queries inside HTML wrappers, causing "X is not defined" errors.

The SQL query UI buttons are hidden globally via CSS in `pages/+layout.svelte`.

## Escaping < and > Characters

Unescaped `<` and `>` in markdown content break Svelte's parser ("Failed to fetch dynamically imported module" errors). HTML entities (`&lt;`/`&gt;`) don't work because the markdown processor converts them back.

Use inline code backticks instead:

```markdown
<!-- Wrong - breaks Svelte -->
- Conservative (z < 0)
## Top suspects (z > 2)

<!-- Also wrong - markdown converts entities back -->
- Conservative (z &lt; 0)

<!-- Correct - use inline code -->
- Conservative (`z < 0`)
## Top suspects (`z > 2`)
```

## Charts

**IMPORTANT**: Always use custom `<ECharts>` components instead of Evidence's built-in `<LineChart>`, `<BarChart>`, etc. Evidence's chart components have bugs with x-axis label rendering on time series data (they set `formatter: false` which hides labels).

### Required Chart Properties

Every chart MUST have:
1. **Title** - Centered at top
2. **X-axis label** - Centered below the x-axis
3. **Y-axis label** - Rotated 90° and vertically centered along the y-axis

### Using Custom ECharts

Import the ECharts component and build the config in the script section:

```svelte
<script>
    import { ECharts } from '@evidence-dev/core-components';

    // Build config reactively so it updates when query data loads
    $: chartConfig = {
        title: {
            text: 'Your Chart Title',
            left: 'center'
        },
        tooltip: { trigger: 'axis' },
        grid: { left: 80, right: 30, bottom: 80, top: 60 },
        xAxis: {
            type: 'category',
            data: your_query?.map(d => d.x_column) || [],
            axisLabel: { interval: 23, rotate: 45, fontSize: 10 },  // interval controls label spacing
            name: 'X Axis Label',
            nameLocation: 'center',
            nameGap: 60
        },
        yAxis: {
            type: 'value',
            name: 'Y Axis Label',
            nameLocation: 'center',
            nameGap: 50,
            nameRotate: 90
        },
        series: [{
            data: your_query?.map(d => d.y_column) || [],
            type: 'line',
            itemStyle: { color: '#2563eb' },
            lineStyle: { color: '#2563eb' }
        }]
    };
</script>

<ECharts config={chartConfig} height="500px" />
```

### Key Settings

- `height="500px"` - Set chart height as a string with px suffix (default is 291px)
- `xAxis.axisLabel.interval` - Controls which labels to show (e.g., `23` shows every 24th label for hourly data with daily labels)
- `xAxis.axisLabel.rotate` - Rotate labels to prevent overlap (e.g., `45` degrees)
- `tooltip: { trigger: 'axis' }` - Shows tooltip on hover
- Use `$:` reactive declaration so config updates when query data loads

### Multi-Series Charts

For charts with multiple series (e.g., by client type), transform the data:

```javascript
$: multiSeriesConfig = (() => {
    if (!query_data || query_data.length === 0) return {};

    const xValues = [...new Set(query_data.map(d => d.x_col))];
    const seriesNames = [...new Set(query_data.map(d => d.series_col))];

    // Build lookup map
    const dataMap = {};
    query_data.forEach(d => {
        if (!dataMap[d.series_col]) dataMap[d.series_col] = {};
        dataMap[d.series_col][d.x_col] = d.y_col;
    });

    const colors = ['#2563eb', '#dc2626', '#16a34a', '#9333ea', '#ea580c'];
    const series = seriesNames.map((name, i) => ({
        name: name,
        type: 'line',
        data: xValues.map(x => dataMap[name]?.[x] || 0),
        itemStyle: { color: colors[i % colors.length] },
        lineStyle: { color: colors[i % colors.length] }
    }));

    return {
        title: { text: 'Chart Title', left: 'center' },
        tooltip: { trigger: 'axis' },
        legend: { data: seriesNames, right: 10, orient: 'vertical', top: 'center' },
        grid: { left: 80, right: 120, bottom: 80, top: 60 },
        xAxis: { type: 'category', data: xValues, axisLabel: { interval: 23, rotate: 45 } },
        yAxis: { type: 'value' },
        series: series
    };
})();
```

### Section Headers in Investigation

Use descriptive action-based headers instead of generic "X Analysis" names:

```markdown
<!-- Wrong -->
### Attester Analysis
### Proposer Analysis

<!-- Correct -->
### When Attesting
### When Proposing
```

## Investigation Page Structure

Investigation pages follow a consistent structure. The Question section serves as the visual hook (the frontmatter `description` is only for SEO).

```
[Title - from frontmatter, rendered by layout]
[PageMeta - author, date, networks, time range, tags]
[Question - the research question, visually prominent with blue accent]
[Background - context and methodology]
[Investigation - analysis with charts]
[Takeaways - key findings]
```

## Sections

Use the `Section` component to structure investigation pages:

```svelte
<script>
    import Section from '$lib/Section.svelte';
</script>

<Section type="question">
## Question
Your research question here (this IS the hook - don't duplicate in PageMeta description)
</Section>

<Section type="background">
## Background
Context and explanation
</Section>

<Section type="investigation">
## Investigation
### When [Action]
Analysis content with charts
</Section>

<Section type="takeaways">
## Takeaways
- Key finding 1
- Key finding 2
</Section>
```

Section types and their colors:
- `question` - Blue left border (4px) - the visual hook for the investigation
- `background` - Gray left border (muted text)
- `investigation` - Gray left border
- `takeaways` - Green left border (4px) with arrow bullets
