---
title: Head Vote Accuracy by Entity Type
sidebar_position: 2
description: Comparing head vote accuracy across Lido CSM, Rocketpool, Solo Stakers, and the rest of the network
date: 2026-01-20
author: samcm
tags:
  - head-votes
  - attestations
  - validators
  - lido-csm
  - rocketpool
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import SqlSource from '$lib/SqlSource.svelte';
</script>

<PageMeta
    date="2026-01-20"
    author="samcm"
    tags={["head-votes", "attestations", "validators", "lido-csm", "rocketpool"]}
/>

## Background

Every slot, validators attest to what they believe is the current head of the chain. If a block arrives late or propagates slowly, attesters may vote for the *parent* block instead of the new one. This "incorrect" head vote isn't the attester's fault - they voted for what they saw.

**Head vote accuracy** measures how often these attestations match the canonical chain head. A lower accuracy typically indicates:
- Blocks arriving late at the attester's node
- Network propagation issues
- Infrastructure or connectivity problems

### Entity groups

This investigation compares head vote accuracy across community staking operators:
- **Lido CSM** - Community Staking Module operators (permissionless entry into Lido)
- **Rocketpool** - Decentralized staking protocol operators
- **Solo Stakers** - Independent home validators
- **Other** - Everyone else (professional operators, exchanges, etc.)

```sql attester_by_blobs
select * from xatu_cbt.head_accuracy_attester_by_blobs
```

```sql proposer_by_blobs
select * from xatu_cbt.head_accuracy_proposer_by_blobs
```

## Attester Analysis

When validators from each entity group attest, how often do they vote for the correct head? This reflects whether they're seeing blocks on time.

### Head Votes by Blob Count

Shows how each entity group's head votes change with blob count.

<SqlSource source="xatu_cbt" query="head_accuracy_attester_by_blobs" />

<LineChart
    data={attester_by_blobs}
    x="blob_count"
    y="head_accuracy_pct"
    series="entity_group"
    xAxisTitle="Blob count"
    yFmt="num2"
    chartAreaHeight=400
    markers=true
    markerSize=6
    lineWidth=2
    yMax=100
    colorPalette={['#10b981', '#f59e0b', '#8b5cf6']}
/>

## Proposer Analysis

When each entity group proposes a block, how many attesters vote for it as head? This reflects how well their blocks propagate to the network.

### Head Votes by Blob Count

Shows how head vote percentage changes with blob count for each entity group.

<SqlSource source="xatu_cbt" query="head_accuracy_proposer_by_blobs" />

<LineChart
    data={proposer_by_blobs}
    x="blob_count"
    y="head_vote_pct"
    series="entity_group"
    xAxisTitle="Blob count"
    yFmt="num2"
    chartAreaHeight=400
    markers=true
    markerSize=6
    lineWidth=2
    yMax=100
    colorPalette={['#10b981', '#6b7280', '#f59e0b', '#8b5cf6']}
/>

