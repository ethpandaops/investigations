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
date: 2025-01-20
author: samcm
tags:
  - tag1
  - tag2
---
```

### Required Fields

- `title`: The page title (displayed in browser tab and navigation)
- `description`: Brief description for SEO and page previews

### Optional Fields

- `sidebar_position`: Order in the sidebar navigation (lower = higher)
- `date`: Publication/update date in YYYY-MM-DD format
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

Use the `PageMeta` component to display the metadata on the page:

```svelte
<script>
    import PageMeta from '$lib/PageMeta.svelte';
</script>

<PageMeta
    date="2025-01-20"
    author="samcm"
    tags={["tag1", "tag2"]}
/>
```

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

### Required Chart Properties

Every chart MUST have:
1. **Title** - Always provide a descriptive `title` prop (centered)
2. **X-axis label** - Centered below the x-axis
3. **Y-axis label** - Rotated 90° and vertically centered along the y-axis

### Configuring Chart Titles and Axis Labels

Evidence uses ECharts. Use `echartsOptions` to configure titles and axis labels.

**Important**: ECharts' built-in `yAxis.nameLocation: 'center'` does NOT properly center the y-axis label vertically. Use the `graphic` component instead for true vertical centering.

```svelte
<LineChart
    data={your_data}
    x="x_column"
    y="y_column"
    series="series_column"
    title="Your Chart Title"
    yFmt="num2"
    chartAreaHeight=400
    yMax=100
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'X Axis Label', nameLocation: 'center', nameGap: 35},
        yAxis: {min: 0, max: 100},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Y Axis Label',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>
```

Key settings:
- `title.left: 'center'` - Centers the chart title
- `grid.bottom: 50` - Makes room for the x-axis label
- `grid.left: 70` - Makes room for the y-axis label and tick marks
- `xAxis.nameLocation: 'center'` - Centers the x-axis label
- `graphic` with `top: 'center'` and `rotation: Math.PI / 2` - Creates a properly centered, rotated y-axis label
- `graphic.left: 15` - Adjust this value to position label closer/further from axis

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

## Sections

Use the `Section` component to structure investigation pages:

```svelte
<script>
    import Section from '$lib/Section.svelte';
</script>

<Section type="question">
## Question
Your research question here
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
- `question` - Blue left border
- `background` - Gray left border (muted text)
- `investigation` - Gray left border
- `takeaways` - Green left border with arrow bullets
