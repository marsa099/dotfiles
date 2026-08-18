---
name: Pi Remote
description: A calm mobile conversation surface for one independently rendered Pi session.
colors:
  primary: "#315eea"
  primary-strong: "#244bc6"
  primary-soft: "#e9eeff"
  canvas: "#f7f7f5"
  surface: "#ffffff"
  surface-soft: "#efefec"
  text: "#1b1b19"
  text-soft: "#666661"
  line: "#deded9"
  line-strong: "#c8c8c1"
  success: "#18794e"
  warning: "#936100"
  danger: "#c23434"
  dark-canvas: "#151514"
  dark-surface: "#1d1d1b"
  dark-text: "#f1f1ed"
  dark-line: "#353532"
typography:
  headline:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 720
    lineHeight: 1.25
    letterSpacing: "-0.025em"
  title:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "1rem"
    fontWeight: 720
    lineHeight: 1.25
    letterSpacing: "-0.02em"
  body:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "0.97rem"
    fontWeight: 400
    lineHeight: 1.62
  label:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 650
    lineHeight: 1.4
rounded:
  sm: "0.35rem"
  md: "0.75rem"
  lg: "1rem"
  bubble: "1.25rem"
  pill: "999px"
spacing:
  xs: "0.35rem"
  sm: "0.55rem"
  md: "0.75rem"
  lg: "1rem"
  xl: "1.5rem"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "0.75rem 1rem"
    height: "3.25rem"
  status-chip:
    backgroundColor: "{colors.surface-soft}"
    textColor: "{colors.text-soft}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "0.35rem 0.68rem"
  composer:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.lg}"
    padding: "0.4rem 0.4rem 0.4rem 0.85rem"
    height: "3.25rem"
---

# Design System: Pi Remote

## Overview

**Creative North Star: "The Clear Relay"**

Pi Remote uses a familiar, calm mobile conversation model while making its unique mechanism visible in one restrained gesture: a route line connecting the laptop, one Pi session, and this phone. The interface is operational rather than expressive. Conversation remains dominant; network state, tools, and queue controls appear exactly where they affect the next action.

The system follows the user's chosen ChatGPT and Claude craft bar without copying either product's branding. Neutral fields, one operational blue, flat transcript content, compact disclosures, and a fixed composer keep long coding sessions readable. It explicitly avoids fake-terminal styling, neon console imagery, and decorative dashboard chrome.

**Key Characteristics:**
- Conversation-first hierarchy with a 46rem maximum reading column.
- One blue accent reserved for connection, focus, streaming, and send actions.
- Tool activity collapses into quiet full-width disclosure rows.
- Light and dark palettes follow the device color scheme.
- Touch controls respect mobile safe areas and remain at least 44px tall.

## Colors

The palette is restrained: cool-neutral surfaces carry almost the entire screen, while operational blue and semantic status colors remain rare and literal.

### Primary
- **Relay Blue**: Used for connection state, focus rings, the send action, and the active phone node.
- **Relay Blue Strong**: Used only for primary-action hover and press emphasis.
- **Relay Blue Wash**: Used behind active or queued state without creating a card hierarchy.

### Neutral
- **Cool Canvas**: The light-mode page field.
- **Clean Surface**: Inputs and raised controls.
- **Soft Surface**: Quiet controls, user messages, code labels, and empty-state support.
- **Deep Ink**: Primary copy.
- **Soft Ink**: Metadata, labels, and supporting copy.
- **Quiet Rule**: Transcript and disclosure dividers.
- **Night Canvas / Night Surface / Night Ink / Night Rule**: Dark-mode counterparts that stay neutral rather than blue-black.

### Semantic
- **Success Green**: Ready and successful tool states.
- **Warning Ochre**: Reserved for recoverable attention states.
- **Failure Red**: Errors, failed tools, and stop actions.

**The One Signal Rule.** Relay Blue marks live interaction or transport state; it does not decorate neutral content.

**The Neutral Night Rule.** Dark mode remains charcoal-neutral. Do not drift toward a blue-black terminal ground.

## Typography

**Display Font:** none; this is an operating surface, not a promotional page.
**Body Font:** the native UI sans stack.
**Label/Mono Font:** SFMono-Regular, Consolas, or Liberation Mono for code and machine data only.

**Character:** Native UI type keeps the interface fast and familiar across phone platforms. Hierarchy comes from weight, spacing, and reading measure rather than a branded display face.

### Hierarchy
- **Headline** (720, 1.25rem, 1.25): Markdown section headings inside assistant responses.
- **Title** (720, 1rem, 1.25): Product and compact surface titles.
- **Body** (400, 0.97rem, 1.62): Assistant prose, limited to roughly 72 characters per line.
- **Label** (650, 0.75rem, 1.4): Status, metadata, queue controls, and disclosure summaries.
- **Code** (400, 0.8rem, 1.55): Fenced code, arguments, and tool output.

**The Prose First Rule.** Monospace belongs to code, paths, commands, and data. Never use it to make the product look technical.

## Layout

The app is a three-row viewport shell: session header, independently scrolling transcript, and safe-area-aware composer. Header, transcript, active tools, and composer share a 46rem maximum width. The transcript uses a flat vertical flow; user messages align right in bounded bubbles while assistant content spans the reading column.

At phone widths the status, queue choice, stop action, and send action remain reachable without horizontal scrolling. Below 22rem, status text becomes visually hidden and the dot carries the state with an accessible label. At 48rem and above, spacing increases but the reading measure does not. Smart follow keeps the newest content visible until the user scrolls away, then a floating jump action restores the live position.

## Elevation & Depth

The transcript is flat by default. Depth appears only where a control must float above changing content: the composer, jump-to-latest action, and temporary notice. Raised surfaces use soft blurred shadows with visible vertical offset; borders and tonal layers carry every other separation.

### Shadow Vocabulary
- **Composer Lift** (`0 4px 18px rgba(20,20,18,0.07), 0 1px 4px rgba(20,20,18,0.04)`): Anchors the input surface above the transcript.
- **Floating Control** (`0 8px 28px rgba(23,24,22,0.10), 0 2px 8px rgba(23,24,22,0.06)`): Used only for transient notices and jump controls.

**The Flat Transcript Rule.** Messages and tool rows do not receive ambient card shadows.

## Shapes

Controls use gently curved corners: small radii for inline code, medium radii for disclosures and notices, and 1rem radii for fields and primary controls. Pills are reserved for status and segmented choices. User messages use a rounded bubble with one tightened lower corner to clarify authorship without alternating colored cards.

Borders are one-pixel neutral rules. Icons are authored 24px SVG strokes with round joins and a consistent 1.8 stroke weight.

## Components

### Buttons
- **Primary:** Relay Blue, white text, 1rem corners, and a 3.25rem touch height.
- **Icon:** Circular or compact rounded hit area with transparent rest state and tonal hover state.
- **Stop:** Failure Red on a red wash with a small square stop mark.
- **Focus:** A three-pixel mixed-blue outline outside the component.

### Status Chips
- **Style:** Neutral pill with a small state dot and short direct label.
- **State:** Ready uses Success Green; working and queued use Relay Blue; offline and error use Failure Red.
- **Motion:** Only the working dot breathes. Reduced-motion clients receive an immediate static state.

### Messages
- **User:** Right-aligned neutral bubble with a bounded width.
- **Assistant:** Flat prose directly on the canvas with full Markdown rhythm.
- **System:** Quiet bordered neutral block for compaction and branch summaries.

### Tool Disclosures
- **Style:** Full-width rows separated by horizontal rules, never nested cards.
- **Default:** Tool name, status dot, and chevron.
- **Expanded:** Monospace arguments or output below the summary.

### Composer
- **Style:** Raised neutral input with an auto-growing textarea and actions on the right.
- **Busy state:** A segmented choice above the field selects Steer next or Follow up; Stop remains visible inside the composer.
- **Send state:** Disabled until connected with non-empty input; Relay Blue when actionable.

### Renderer Route
- **Style:** A single horizontal line with Laptop, Pi session, and This phone nodes.
- **Purpose:** Explain independent rendering in one glance without becoming navigation or dashboard chrome.

## Do's and Don'ts

### Do:
- **Do** keep assistant prose flat, readable, and limited to the shared content width.
- **Do** expose agent and queue state before the user sends a message.
- **Do** use compact expandable tool rows for progressive disclosure.
- **Do** preserve device color scheme, reduced motion, safe areas, and visible keyboard focus.
- **Do** use authored SVG icons with the established stroke grammar.

### Don't:
- **Don't** render terminal bytes, ANSI styling, or a simulated console.
- **Don't** turn messages and tools into a stack of same-sized cards.
- **Don't** use Relay Blue as decoration or add competing accent colors.
- **Don't** hide a working session's delivery choice or stop control.
- **Don't** use monospace outside code and machine data.
