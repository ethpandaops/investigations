---
title: FCR Implementation Divergence
sidebar_position: 2
description: Two implementations of consensus-specs PR #4747 (Fast Confirmation Rule) disagree on 1.2% of mainnet slots. Tracing the gap back to a non-spec extension in a Teku research branch that adds same-slot parent-vote weight to the safety-threshold discount.
date: 2026-05-14T00:00:00Z
author: samcm
tags:
  - consensus
  - fast-confirmation
  - fork-choice
  - lighthouse
  - teku
---

<script>
    import PageMeta from '$lib/PageMeta.svelte';
    import Section from '$lib/Section.svelte';
    import { ECharts } from '@evidence-dev/core-components';

    const overlapData = [
        { name: 'Both confirmed', value: 186874, color: '#16a34a' },
        { name: 'Teku confirmed, Lighthouse not', value: 2388, color: '#dc2626' },
        { name: 'Lighthouse confirmed, Teku not', value: 143, color: '#9333ea' },
        { name: 'Both unconfirmed', value: 5785, color: '#9ca3af' }
    ];

    $: overlapConfig = {
        title: { text: '195,190-slot overlap: where the two implementations agree and disagree', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: {
            trigger: 'item',
            formatter: (p) => `<b>${p.name}</b><br/>${p.value.toLocaleString()} slots (${(p.percent).toFixed(2)}%)`
        },
        legend: { orient: 'vertical', right: 10, top: 'center' },
        series: [{
            type: 'pie',
            radius: ['40%', '70%'],
            center: ['38%', '55%'],
            avoidLabelOverlap: true,
            label: { show: true, formatter: '{b}\n{d}%' },
            labelLine: { show: true },
            data: overlapData.map(d => ({ name: d.name, value: d.value, itemStyle: { color: d.color } }))
        }]
    };

    const thresholdComponents = [
        { name: 'Lighthouse', max_support: 2227064, support: 1660301, proposer: 445412, adversarial: 556766, discount: 0, threshold: 1893004, verdict: 'FAIL by 233k ETH' },
        { name: 'Teku',       max_support: 2227064, support: 1654605, proposer: 445412, adversarial: 556766, discount: 544432, threshold: 1620788, verdict: 'PASS by 34k ETH' }
    ];

    $: thresholdConfig = (() => {
        const names = thresholdComponents.map(r => r.name);
        return {
            title: { text: 'Slot 13,184,078: safety threshold breakdown', left: 'center', textStyle: { fontSize: 13 } },
            tooltip: {
                trigger: 'axis',
                axisPointer: { type: 'shadow' },
                formatter: (params) => {
                    let html = `<b>${params[0].axisValue}</b><br/>`;
                    params.forEach(p => { html += `${p.marker} ${p.seriesName}: ${Number(p.value).toLocaleString()} ETH<br/>`; });
                    return html;
                }
            },
            legend: { data: ['proposer_score', 'adversarial_weight', 'support_discount', 'support'], top: 25 },
            grid: { left: 100, right: 30, bottom: 70, top: 70 },
            xAxis: { type: 'value', name: 'ETH', nameLocation: 'center', nameGap: 35, axisLabel: { formatter: (v) => (v/1e6).toFixed(1)+'M' } },
            yAxis: { type: 'category', data: names },
            series: [
                { name: 'proposer_score', type: 'bar', stack: 'threshold', itemStyle: { color: '#9333ea' }, data: thresholdComponents.map(r => r.proposer) },
                { name: 'adversarial_weight', type: 'bar', stack: 'threshold', itemStyle: { color: '#dc2626' }, data: thresholdComponents.map(r => r.adversarial) },
                { name: 'support_discount', type: 'bar', stack: 'threshold', itemStyle: { color: '#ea580c' }, data: thresholdComponents.map(r => -r.discount), label: { show: true, formatter: (p) => p.value === 0 ? '0' : (Number(p.value)/1000).toFixed(0)+'k', position: 'inside' } },
                { name: 'support', type: 'bar', itemStyle: { color: '#16a34a' }, data: thresholdComponents.map(r => r.support), markLine: {
                    silent: true,
                    symbol: 'none',
                    lineStyle: { type: 'dashed', color: '#000' },
                    data: [
                        { name: 'Lighthouse threshold (1.893M)', xAxis: 1893004, label: { show: true, formatter: 'LH threshold', position: 'insideEndTop' } },
                        { name: 'Teku threshold (1.621M)',       xAxis: 1620788, label: { show: true, formatter: 'Teku threshold', position: 'insideEndBottom' } }
                    ]
                } }
            ]
        };
    })();

    const sourceCompareData = [
        { name: 'Block-included', value: 27990, color: '#16a34a' },
        { name: 'Gossip-pool (2 sentries)', value: 27865, color: '#2563eb' }
    ];

    $: sourceCompareConfig = {
        title: { text: 'Distinct attesting validators per slot (50,400-slot mean)', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (params) => `<b>${params[0].name}</b><br/>${params[0].value.toLocaleString()} validators` },
        grid: { left: 160, right: 60, top: 60, bottom: 40 },
        xAxis: { type: 'value', min: 27500, max: 28100, name: 'validators', nameLocation: 'center', nameGap: 25 },
        yAxis: { type: 'category', data: sourceCompareData.map(d => d.name) },
        series: [{
            type: 'bar',
            data: sourceCompareData.map(d => ({ value: d.value, itemStyle: { color: d.color } })),
            label: { show: true, position: 'right', formatter: (p) => Number(p.value).toLocaleString() }
        }]
    };

    const deltaBucketData = [
        { name: 'block − gossip in (50, 100]', value: 36759 },
        { name: 'block − gossip in (100, 200]', value: 7647 },
        { name: 'block − gossip in (200, 500]', value: 4320 },
        { name: 'block − gossip > 500', value: 1674 }
    ];

    $: deltaBucketConfig = {
        title: { text: 'Per-slot voter gap (block-included minus gossip), 50,400 slots', left: 'center', textStyle: { fontSize: 13 } },
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, formatter: (params) => {
            const total = 50400;
            const v = params[0].value;
            return `<b>${params[0].name}</b><br/>${v.toLocaleString()} slots (${(100 * v / total).toFixed(1)}%)`;
        } },
        grid: { left: 200, right: 80, top: 60, bottom: 40 },
        xAxis: { type: 'value', name: 'slots', nameLocation: 'center', nameGap: 25 },
        yAxis: { type: 'category', data: deltaBucketData.map(d => d.name) },
        series: [{
            type: 'bar',
            data: deltaBucketData.map(d => ({ value: d.value, itemStyle: { color: '#0ea5e9' } })),
            label: { show: true, position: 'right', formatter: (p) => `${Number(p.value).toLocaleString()} (${(100 * p.value / 50400).toFixed(1)}%)` }
        }]
    };
</script>

<PageMeta
    date="2026-05-14T00:00:00Z"
    author="samcm"
    tags={["consensus", "fast-confirmation", "fork-choice", "lighthouse", "teku"]}
    networks={["Ethereum Mainnet"]}
    startTime="2025-12-06T00:00:00Z"
    endTime="2026-01-02T23:59:59Z"
/>

<Section type="question">

## Question

Two independent implementations of consensus-specs [PR #4747](https://github.com/ethereum/consensus-specs/pull/4747) (Fast Confirmation Rule) disagree on 1.2% of mainnet slots over the same epoch range. Where does the divergence come from, and which one matches the spec?

</Section>

<Section type="background">

## Background

The **Fast Confirmation Rule** (FCR) is a proposed addition to the consensus-specs ([PR #4747](https://github.com/ethereum/consensus-specs/pull/4747)) that lets a node locally **confirm** a block within seconds of the attestation deadline, well ahead of FFG finality. The [previous FCR investigation](/2026-03/fast-confirmation-rule/) reported a 96.9% confirmation rate on a 131-day mainnet window using a simplified head-vote proxy.

Two implementations of the rule now exist:

- **Lighthouse**: [sigp/lighthouse#8951](https://github.com/sigp/lighthouse/pull/8951), a from-spec implementation tracking PR #4747.
- **Teku research branch**: the basis for the Teku-based replay in the previous FCR investigation.

We built a simulator on top of the Lighthouse implementation ([ethpandaops/fcr-simulator](https://github.com/ethpandaops/fcr-simulator)) and ran it across **epochs 412000–418139**, the same 195,190-slot range the Teku replay covered. Same window, two implementations. The goal here is to characterise where they disagree and why.

There's a second axis to keep in mind. The two implementations are also fed attestations from different sources. The Lighthouse simulator reads attestations out of canonical block bodies, which is a proposer-curated subset, capped per Electra by `MAX_ATTESTATIONS_ELECTRA = 8` aggregates per block. The Teku research replay reads aggregates from the `libp2p_gossipsub_aggregate_and_proof` table in xatu, filtered to a small set of sentry clients (the gossip-pool view). The disagreement we are explaining is therefore "implementation logic plus data source", and we want to know how much of the 1.15 pp comes from each.

</Section>

<Section type="investigation">

## Investigation

### When counting agreements and disagreements

Over the 195,190-slot overlap (epochs 412000–418139), Teku reports a 96.96% confirmation rate; Lighthouse reports 95.81%. The 1.15 percentage point gap is real and one-sided. Almost all of it comes from slots Teku confirms that Lighthouse does not.

<ECharts config={overlapConfig} height="380px" />

| Category | Slots | Share |
|---|---:|---:|
| Both confirmed | 186,874 | 95.74% |
| Both unconfirmed | 5,785 | 2.96% |
| Teku confirmed, Lighthouse did not | **2,388** | **1.22%** |
| Lighthouse confirmed, Teku did not | 143 | 0.07% |
| **Total** | 195,190 | 100% |

The 143 reverse-disagreement slots are noise: different state snapshots, edge cases on the boundary. The substantive gap is the 2,388 slots Teku is more confident about. That entire bucket is what we need to explain.

### When comparing the two attestation data sources

Before chasing the implementation logic we wanted to put a number on the data-source axis. The two replays are seeing different attestation sets:

- **Lighthouse simulator**: attestations extracted from canonical block bodies. Each block carries at most `MAX_ATTESTATIONS_ELECTRA = 8` aggregates, chosen by the proposer from whatever they had locally at proposal time.
- **Teku-based replay**: aggregates from xatu's `libp2p_gossipsub_aggregate_and_proof` table, filtered to a small set of sentry clients. This is the gossip-pool view: every aggregate that reached at least one of those sentries, regardless of whether any block ever included it.

The original disagreement window (epochs 412000–418139, December 2025 to January 2026) is now outside xatu's gossip-table retention (~43 days), so we cannot redo the comparison on the exact slots that drove the 1.15 pp gap. Instead we ran the comparison on a recent **50,400-slot window** (epochs 445837–447412, slots 14,266,799–14,317,198, 2026-05-06 to 2026-05-13), well within retention.

For each slot we computed two numbers:

- **block_voters**: the count of distinct validator indices present in the `validators` array across every block-included aggregate from `canonical_beacon_elaborated_attestation` whose attested slot equals the slot in question (within a 32-slot inclusion window).
- **gossip_voters**: the count of distinct (committee_index, bit_position) pairs voting across the union of all `aggregation_bits` for the slot in `libp2p_gossipsub_aggregate_and_proof`, restricted to the sentries that are currently emitting (`ethpandaops/mainnet/utility-mainnet-lighthouse-geth-001` and `-003`; the other three sentry clients from the original replay are no longer producing data).

<ECharts config={sourceCompareConfig} height="180px" />

| Source | Mean | Median | P5 | P95 | Min | Max |
|---|---:|---:|---:|---:|---:|---:|
| Block-included | 27,990 | 27,996 | — | — | 27,036 | 28,046 |
| Gossip-pool (2 sentries) | 27,865 | 27,915 | — | — | 25,814 | 27,980 |
| **block − gossip** | **+126** | **+75** | **+65** | **+393** | **+63** | **+2,163** |

The average mainnet committee total in this window is ~28,060 validators per slot. Block-included aggregates capture ~99.75% of the committee on average; the 2-sentry gossip view captures ~99.30%. The mean per-slot delta is about 126 validators (~0.45% of committee), and the delta is **always positive in the window**. Block-included sees at least 63 more voters than the 2-sentry gossip view in every single slot. The distribution:

<ECharts config={deltaBucketConfig} height="240px" />

- 72.9% of slots: block sees 50–100 more voters than gossip
- 15.2% of slots: 100–200 more
- 8.6% of slots: 200–500 more
- 3.3% of slots: more than 500 more
- 0 slots: gossip sees more

The direction is the opposite of what the naive "gossip-pool sees everything that propagated" framing predicts. The reason is that only 2 of the original 5 sentries are currently emitting; two listening points can't reconstruct the full gossip mesh, while a block aggregator pools from a much wider peer set. With all 5 sentries online the gossip count would likely be higher. The previous investigation's slot-78 spike noted ~14,837 gossip voters vs 14,729 in-block (a +0.7% gap in the *other* direction). Either way, the data-source gap sits at the ~0.5%-of-committee scale.

Take-away: the data-source axis is real but small. It cannot account for the 1.15 pp confirmation-rate gap on its own. A 0.5% shift in attesting weight is well inside the noise of the safety threshold, and it tilts in the direction of *more* support for canonical heads in blocks, not less. Caveat: we cannot rerun this on the exact 412000–418139 window because of retention, so we are extrapolating from a recent slot range and the previous slot-78 spike. With that caveat, the data-source axis is not where the 1.15 pp lives. The implementation logic is.

### When isolating a single disagreement

We picked **slot 13,184,078** as a representative case. The block at slot 78 (`0xe9c236...`) arrived late: at slot 78's attestation deadline, only **14,729** of ~31,000 validators in slot 78's committee had seen it. The other **16,194** voted for the parent (`0xd58f96...`, slot 77's canonical block).

The disagreement actually appears one slot later, at slot 13,184,079 (Teku confirmed, Lighthouse did not). The block at slot 79 (`0xbadf6ba0`) had 30,823 distinct validators voting for it, about 99% by count. Plenty of weight.

Why didn't Lighthouse confirm? FCR's `find_latest_confirmed_descendant` walks ancestors and breaks on the first failure. To confirm slot 79, the chain check has to independently pass slot 78. The suffix-sum scoring (`get_attestation_score`) means slot 79's voters count toward slot 78's score as well: `14,729 + 30,823 = 45,552` distinct validators with `current_root` in slot 78's subtree.

We computed exact effective balances from the BN at slot 13,184,080's state for all 45,546 of those distinct voters. Total support for slot 78 in the 2-slot evaluation window: **1,656,717 ETH**. The Teku log for the same slot reports support of **1,654,605 ETH**. We have **more** support than Teku does, yet Lighthouse still fails the threshold and Teku still passes it. The gap can't be on the support side. It has to be in the threshold itself.

### When inspecting the threshold

We ran the Lighthouse engine with `RUST_LOG=beacon_chain::fast_confirmation=debug` against a targeted 1-epoch slice and captured the exact `is_one_confirmed_with_score` numbers, then put them next to the Teku logs for the same slot:

| Field | Lighthouse | Teku (log) |
|---|---:|---:|
| support | 1,660,301 ETH | 1,654,605 ETH |
| max_support | 2,227,064 ETH | 2,227,064 ETH |
| proposer_score | 445,412 ETH | 445,412 ETH |
| adversarial_weight (2-slot) | 556,766 ETH | 556,766 ETH |
| **support_discount** | **0 ETH** | **544,432 ETH** |
| **safety_threshold** | **1,893,004 ETH** | **1,620,788 ETH** |
| Verdict | **FAIL by 233k ETH** | **PASS by 34k ETH** |

Every component agrees except `support_discount`. Teku subtracts 544,432 ETH from its threshold; Lighthouse subtracts zero. The size of that delta is not a coincidence: it equals the weight of the 16,194 validators that voted for the parent at slot 78's deadline.

<ECharts config={thresholdConfig} height="320px" />

The chart makes the picture concrete. Both implementations agree on the components going **into** the threshold (proposer_score + adversarial_weight). They disagree on the discount coming **out**. With Teku's larger discount the threshold drops below the support and the block confirms; with no discount the threshold sits above support and the block fails.

### When reading the spec

The spec defines `compute_empty_slot_support_discount` ([fast-confirmation.md on `mkalinin:fast-conf-rule`](https://github.com/ethereum/consensus-specs/pull/4747)):

```python
if parent_block.slot + 1 == block.slot:
    return Gwei(0)
```

Lighthouse matches verbatim (`lighthouse/beacon_node/beacon_chain/src/fast_confirmation.rs:1064`):

```rust
if parent_slot.saturating_add(1u64) == block_slot {
    return Ok(0);
}
```

For slot 78 with parent at slot 77, `77 + 1 == 78`, so the spec function returns 0. There is no empty-slot discount to apply, because there is no empty slot. Lighthouse is doing exactly what the spec says.

The Teku research branch (`ConfirmationRuleUtil.java`, `getSupportDiscount`) does something different:

```java
UInt64 emptySlotSupport = computeEmptySlotSupportDiscount(...);   // spec-compliant, = 0
UInt64 parentBlockSupport =                                       // non-spec addition
    getBlockSupportInSlots(store, balanceSource, parentRoot, blockSlot, blockSlot);
return emptySlotSupport.plus(parentBlockSupport);
```

Teku adds a second term: `parentBlockSupport`, evaluated **at the block's own slot** (`blockSlot, blockSlot`). The spec's `get_support_discount` has no such term. For our example slot, this term returns the weight of the 16,194 parent-voters, which matches the 544,432 ETH delta we observed exactly. The same shape holds on the rest of the 2,388 disagreement slots: every time Teku confirms and Lighthouse does not, it is because Teku's larger discount pulls the safety threshold below support.

This looks deliberate. A validator that already attested for the parent at the block's own slot cannot, without equivocating, then support a competing slot-N child. From an adversary's point of view that weight is "honest unavailable", so it can't be used against the confirmation. Treating it as a discount is a defensible tightening of the safety threshold. But it is not in the current spec text, and it is not in the initial commit of the spec either: the only support_discount the spec defines is the empty-slot one.

</Section>

<Section type="takeaways">

## Takeaways

- The 1.15 pp gap between Teku (96.96%) and Lighthouse (95.81%) on the same 195,190-slot range is **driven by the implementation logic, not the data source**. The data-source axis (block bodies vs 2-sentry gossip pool) sits at ~0.5% of committee on a recent 50,400-slot window and tilts in the direction of *more* block-included voters, not fewer.
- The implementation gap is Teku's non-spec `support_discount` term. Lighthouse matches PR #4747 verbatim; the Teku research branch adds a same-slot parent-vote term that the spec does not define. Across the 2,388 disagreement slots, every "Teku-yes, Lighthouse-no" is explained by Teku's larger discount pulling the safety threshold below support.
- This is not "Lighthouse is wrong". On PR #4747 as currently written, Lighthouse is spec-correct and the conservative number (~95.8%) is the strict-spec FCR rate on this range.
- The headline 96.9% from the [previous FCR investigation](/2026-03/fast-confirmation-rule/) includes ~1.15 pp of confirmations that strict-spec FCR would not make. The spec-correct number on the same epoch range is ~95.8%.
- The same-slot parent-vote extension is plausibly an **improvement** worth proposing for the spec: validators that voted for the parent at slot N cannot non-equivocatingly support a competing slot-N child, so their weight is fair to discount. It is a coherent tightening, but it needs to be stated and tested as a spec change.
- Action items: if the Teku branch is meant to track PR #4747 strictly, drop the `parentBlockSupport` term from `getSupportDiscount`. If the extension is the intended design, propose it as a follow-up to PR #4747. Either way, the 12-month FCR run we are producing on [fcr-simulator](https://github.com/ethpandaops/fcr-simulator) is on spec-strict Lighthouse and will report the conservative number.
- Data-source caveat: we could not replay the exact 412000–418139 disagreement window because the gossip-aggregate table has ~43-day retention. The data-source comparison above is on a recent 50,400-slot window (epochs 445837–447412) and uses 2 of the original 5 sentries (the others are no longer emitting). The gap looks small in both directions across the data we have.

</Section>
