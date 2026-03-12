---
title: ripemd160
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
</script>

<PageMeta
    date="2026-03-12T00:00:00Z"
    authors={["samcm", "mattevans"]}
    tags={["precompiles", "execution", "ripemd160"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-29T00:00:00Z"
    endTime="2026-02-26T23:59:59Z"
/>

<Section type="question">

## Question

Is anyone still using the ripemd160 precompile?

</Section>

<Section type="background">

## Background

**ripemd160** (`0x03`) computes the RIPEMD-160 hash, originally included in the EVM because Bitcoin uses it for address derivation. Gas cost: 600 base + 120 per 32-byte word.

With only 233 calls over the entire analysis period (~426K blocks), ripemd160 is the least-used precompile by a wide margin. It's essentially dead — whatever contracts call it, they do so very rarely.

</Section>

<Section type="investigation">

## Investigation

With only 233 calls across ~60 days, there's not enough activity to produce meaningful charts. A ~6,000 block sample window found zero ripemd160 calls, which tells you everything about how rarely this precompile gets used.

For context, ripemd160 averages about 4 calls per day across the entire network.

</Section>

<Section type="takeaways">

## Takeaways

- ripemd160 is effectively dead: 233 calls over ~60 days
- Originally included for Bitcoin address compatibility, but that use case never materialized on Ethereum
- A strong candidate for deprecation discussions in future hard forks

</Section>
