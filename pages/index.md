---
title: ethPandaOps Investigations
sidebar_position: 0
queries: []
---

<style>
h1:first-of-type { display: none !important; }
</style>

<div style="display: flex; align-items: center; gap: 3rem; margin: 1rem 0 2.5rem 0; padding: 2.5rem 0;">
    <img src="/investigations/panda.png" alt="Investigation Panda" style="width: 200px; height: auto; flex-shrink: 0; filter: drop-shadow(4px 6px 12px rgba(61, 58, 42, 0.2));" />
    <div>
        <div style="font-family: 'Courier New', monospace; font-size: 2.2rem; font-weight: 700; letter-spacing: 0.15em; color: #3d3a2a; margin-bottom: 0.5rem; text-shadow: 1px 1px 0 rgba(255,255,255,0.8);">
            CASE FILES
        </div>
        <div style="width: 80px; height: 3px; background: linear-gradient(90deg, #bb5a38, #d4a090); margin-bottom: 1.25rem;"></div>
        <p style="font-size: 0.95rem; color: #5c5650; line-height: 1.7; margin: 0;">
            When something interesting happens on the network, we investigate. These one-off analyses are part of our daily workflow at <a href="https://ethpandaops.io" style="color: #bb5a38; text-decoration: none; font-weight: 500;">ethPandaOps</a> and are archived here so the findings and learnings aren't blackholed in our Discord.
        </p>
        <p style="font-size: 0.9rem; color: #5c5650; line-height: 1.7; margin-top: 1rem; max-width: 420px;">
           Powered by <a href="https://ethpandaops.io/data/xatu" style="color: #bb5a38; text-decoration: none; font-weight: 600;">Xatu</a> data.
        </p>
    </div>
</div>

<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.25rem;">
    <a href="/investigations/2026-01/timing-games" style="display: block; padding: 1.5rem 1.75rem; background: linear-gradient(135deg, rgba(248,247,243,0.9) 0%, rgba(244,242,235,1) 100%); border-left: 4px solid #bb5a38; text-decoration: none; transition: all 0.15s ease-out; box-shadow: 0 2px 8px -2px rgba(61,58,42,0.08);">
        <div style="font-family: ui-monospace, monospace; font-size: 0.6rem; letter-spacing: 0.12em; color: #bb5a38; text-transform: uppercase; margin-bottom: 0.5rem; font-weight: 600;">Latest Case</div>
        <div style="color: #3d3a2a; font-weight: 700; font-size: 1.1rem; margin-bottom: 0.4rem;">Timing Games</div>
        <div style="font-size: 0.85rem; color: #6b6560; line-height: 1.5;">Which entities delay their blocks to extract more MEV?</div>
    </a>
    <a href="/investigations/2026-01/private-blob-submitters" style="display: block; padding: 1.5rem 1.75rem; background: rgba(248,247,243,0.7); border-left: 4px solid #d4a090; text-decoration: none; transition: all 0.15s ease-out;">
        <div style="font-family: ui-monospace, monospace; font-size: 0.6rem; letter-spacing: 0.12em; color: #9a958d; text-transform: uppercase; margin-bottom: 0.5rem;">Jan 21</div>
        <div style="color: #3d3a2a; font-weight: 700; font-size: 1.1rem; margin-bottom: 0.4rem;">Private Blob Submitters</div>
        <div style="font-size: 0.85rem; color: #6b6560; line-height: 1.5;">Who posts blobs that bypass the public mempool?</div>
    </a>
    <a href="/investigations/2026-01/head-vote-accuracy" style="display: block; padding: 1.5rem 1.75rem; background: rgba(248,247,243,0.5); border-left: 4px solid #ddd9d1; text-decoration: none; transition: all 0.15s ease-out;">
        <div style="font-family: ui-monospace, monospace; font-size: 0.6rem; letter-spacing: 0.12em; color: #9a958d; text-transform: uppercase; margin-bottom: 0.5rem;">Jan 20</div>
        <div style="color: #3d3a2a; font-weight: 700; font-size: 1.1rem; margin-bottom: 0.4rem;">Head Vote Accuracy</div>
        <div style="font-size: 0.85rem; color: #6b6560; line-height: 1.5;">How often do validators correctly vote for the chain head?</div>
    </a>
    <a href="/investigations/2026-01/snooper-overhead" style="display: block; padding: 1.5rem 1.75rem; background: rgba(248,247,243,0.5); border-left: 4px solid #ddd9d1; text-decoration: none; transition: all 0.15s ease-out;">
        <div style="font-family: ui-monospace, monospace; font-size: 0.6rem; letter-spacing: 0.12em; color: #9a958d; text-transform: uppercase; margin-bottom: 0.5rem;">Jan 16</div>
        <div style="color: #3d3a2a; font-weight: 700; font-size: 1.1rem; margin-bottom: 0.4rem;">RPC Snooper Overhead</div>
        <div style="font-size: 0.85rem; color: #6b6560; line-height: 1.5;">Measuring latency impact of rpc-snooper on Engine API.</div>
    </a>
</div>

<div style="border-top: 1px solid #e8e5dc; margin-top: 3rem; padding-top: 1.5rem; font-size: 0.8rem; color: #9a958d;">
    Built with <a href="https://evidence.dev" style="color: #6b6560; text-decoration: none; border-bottom: 1px solid #ddd9d1;">Evidence</a>&nbsp;&nbsp;·&nbsp;&nbsp;Maintained by <a href="https://ethpandaops.io" style="color: #6b6560; text-decoration: none; border-bottom: 1px solid #ddd9d1;">ethPandaOps</a>
</div>
