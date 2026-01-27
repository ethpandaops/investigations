---
name: create-instructional-image
description: Create an ethPandaOps-style instructional/explainer image for Ethereum concepts. Generates clean whiteboard-aesthetic diagrams following the ethPandaOps/investigations visual style guide. 
---

# Core Philosophy: "Less is More"

The primary goal of EthPandaOps explainer images is instant cognitive comprehension of complex technical topics. The aesthetic is merely a vehicle for clarity. Every element on the screen must serve a functional purpose. If it doesn't aid understanding, remove it. The style is clean, clinical, and highly structured, evoking a master teacher outlining a concept on a fresh whiteboard.

## 1. The Canvas & Foundation
- Background: A clean, brightly lit whiteboard surface. It should have subtle, realistic textures (minimal dry-erase residue, slight surface imperfections) to ground it in reality, but it must never look dirty or cluttered.
- Framing: The physical whiteboard frame (tray with erasers/markers) serves as a subtle boundary but remains peripheral. The focus is entirely on the content within the frame.
- Lighting: Even, bright, clinical lighting. No dramatic shadows.

## 2. Color Palette (Strictly Functional)
Colors are used sparingly and only to communicate state or function. Avoid gradients or purely decorative coloring.
- Primary Charcoal: (e.g., Hex #2C3E50 or similar deep off-black). Used for all primary text, outlines, containers, and neutral icons.
- Functional Green: (e.g., a clear, mid-tone emerald). exclusively for positive states: success, attestation, finalized, active.
- Functional Red: (e.g., a clear, mid-tone crimson). Exclusively for negative states: missed, failed, error, slashing.
- Neutral Grey: Used for inactive, pending, or future states (often combined with dotted lines).

## 3. Typography & Linework
- Font: A clean, modern, highly readable sans-serif font. No handwriting or "sketch" fonts.
- Hierarchy: Bold, large uppercase for Main Titles. Clear, standard weight for labels and secondary text.
- Linework: Precise, consistent medium-weight vector lines. They should look like they were drawn with a high-quality, fresh whiteboard marker—opaque and clean edges, not sketchy or wobbly (this is a key differentiator from other styles like Finematics).

## 4. Composition & Flow
Negative Space: Embrace white space aggressively. Elements must have room to "breathe." Never crowd the diagram.
Containers: Use distinct containers (like the rounded rectangular "cards" in the reference) to isolate individual steps or concepts. This breaks complex chains into digestible chunks.
Flow: Clear, linear progression. Use prominent arrows to guide the viewer's eye (usually left-to-right for time sequences).
The Legend: Always include a clean, succinct legend at the bottom if arbitrary icons are used.

## 5. Reusable Entity Library (Standard Components)
To maintain consistency and speed up production, reuse these standardized visual metaphors.
- An Ethereum Block: A clean, isometric 3D cube outlined in Charcoal. It is the central atom of the diagrams.
- A Concept Container: A rounded-corner rectangular card with a thick Charcoal border. Used to encapsulate a single step (e.g., a "Slot" or an "Epoch").
- State Indicators (Overlays):
  - Check: A simple, thick Green checkmark placed near or over something that is successful.
  - The Missed 'X': A simple, thick Red 'X'.
  - The Finalized Stamp: A stylized rubber stamp icon, usually in Green, denoting immutability.
- Line States:
  - Solid Line: Active, current, or confirmed reality.
  - Dotted/Dashed Line: Pending, future, missed, or hypothetical reality.

## 6. Slot Timeline (Beacon Chain Sequences)
A core building block for Ethereum consensus diagrams. Used to illustrate block proposals, forks, parent references, attestations, and epoch boundaries.

### Construction Rules
- **Uniform spacing**: Slots represent time. Positions must be evenly distributed left-to-right with perfectly uniform gaps. Never compress or shift slots to "fit" — the timeline is the spatial anchor.
- **Horizontal baseline**: A thin charcoal horizontal line with tick marks at each slot position. Labels ("Slot 1", "Slot N") sit below the ticks.
- **Blocks sit on the timeline**: Each slot that has a proposed block gets an isometric 3D cube (with green checkmark) placed above the tick. Missed slots get a Red 'X' at the tick position — no cube.
- **Parent reference arrows point backwards** (right-to-left): Every block references its parent. Arrows go FROM child BACK TO parent. Use solid charcoal arrows for canonical references.

### Showing Forks
When a block builds on a non-canonical parent:
- Drop the forked block **below** the main timeline at its correct slot position. This visually separates it from the canonical chain while preserving its time position.
- Use a **red dashed arrow** for the stale/non-canonical parent reference (pointing backwards to the old parent).
- The canonical chain continues above the timeline, skipping over the forked slot.

### Key Principles
- All blocks are solid and real — don't ghost or fade blocks unless explicitly needed to show a proposer's limited view.
- The timeline position is sacred — never move a slot's horizontal position to make arrows shorter or the layout tidier.
- Fewer annotations are better. The spatial layout (above/below the line, arrow style) should communicate the concept. Only add a short annotation if the visual alone is ambiguous.