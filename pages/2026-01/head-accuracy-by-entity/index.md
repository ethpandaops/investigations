---
title: Head Vote Accuracy by Entity Type
sidebar_position: 2
description: Comparing head vote accuracy across Lido CSM, Rocketpool, Solo Stakers, and the rest of the network
date: 2026-01-20
author: samcm
hidden: true
tags:
  - head-votes
  - attestations
  - validators
  - lido-csm
  - rocketpool
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-20"
    author="samcm"
    tags={["head-votes", "attestations", "validators", "lido-csm", "rocketpool"]}
    description="Comparing head vote accuracy across Lido CSM, Rocketpool, Solo Stakers, and the rest of the network"
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-21T00:00:00Z"
    endTime="2026-01-21T23:59:59Z"
/>

```sql attester_by_blobs
select * from xatu_cbt.head_accuracy_attester_by_blobs
```

```sql proposer_by_blobs
select * from xatu_cbt.head_accuracy_proposer_by_blobs
```

<Section type="question">

## Question

Do community staking operators (Lido CSM, Rocketpool, Solo Stakers) see worse head vote accuracy as blob counts increase?

</Section>

<Section type="background">

## Background

Every slot, validators attest to what they believe is the current head of the chain. If a block arrives late or propagates slowly, attesters may vote for the *parent* block instead of the new one. This "incorrect" head vote isn't the attester's fault - they voted for what they saw.

**Head vote accuracy** measures how often these attestations match the canonical chain head. A lower accuracy typically indicates:
- Blocks arriving late at the attester's node
- Network propagation issues
- Infrastructure or connectivity problems

**Entity groups** compared in this investigation:
- **Lido CSM** - Community Staking Module operators (permissionless entry into Lido)
- **Rocketpool** - Decentralized staking protocol operators
- **Solo Stakers** - Independent home validators
- **Other** - Everyone else (professional operators, exchanges, etc.)

</Section>

<Section type="investigation">

## Investigation

### When Attesting

When validators from each entity group attest, how often do they vote for the correct head? This reflects whether they're seeing blocks on time.

<SqlSource source="xatu_cbt" query="head_accuracy_attester_by_blobs" />

<LineChart
    data={attester_by_blobs}
    x="blob_count"
    y="head_accuracy_pct"
    series="entity_group"
    title="Head Vote Accuracy by Blob Count (Attester View)"
    yFmt="num2"
    chartAreaHeight=400
    markers=true
    markerSize=6
    lineWidth=2
    yMax=100
    colorPalette={['#10b981', '#f59e0b', '#8b5cf6']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'Blob Count', nameLocation: 'center', nameGap: 35},
        yAxis: {min: 0, max: 100},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Head Vote Accuracy (%)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

### When Proposing

When each entity group proposes a block, how many attesters vote for it as head? This reflects how well their blocks propagate to the network.

<SqlSource source="xatu_cbt" query="head_accuracy_proposer_by_blobs" />

<LineChart
    data={proposer_by_blobs}
    x="blob_count"
    y="head_vote_pct"
    series="entity_group"
    title="Head Vote Accuracy by Blob Count (Proposer View)"
    yFmt="num2"
    chartAreaHeight=400
    markers=true
    markerSize=6
    lineWidth=2
    yMax=100
    colorPalette={['#10b981', '#6b7280', '#f59e0b', '#8b5cf6']}
    echartsOptions={{
        title: {left: 'center'},
        grid: {bottom: 50, left: 70, top: 60, right: 30},
        xAxis: {name: 'Blob Count', nameLocation: 'center', nameGap: 35},
        yAxis: {min: 0, max: 100},
        graphic: [{
            type: 'text',
            left: 15,
            top: 'center',
            rotation: Math.PI / 2,
            style: {
                text: 'Head Vote Accuracy (%)',
                fontSize: 12,
                fill: '#666'
            }
        }]
    }}
/>

</Section>

<Section type="takeaways">

## Takeaways

- Solo stakers show comparable head vote accuracy to other entity groups at low blob counts
- As blob counts increase beyond ~20, all groups show declining accuracy, but the effect is more pronounced for home validators
- This suggests that high-blob blocks may propagate slower to residential connections

</Section>
