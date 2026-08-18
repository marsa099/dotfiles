---
version: 1
slug: "web-index-html"
primary_target: "web/index.html"
related_targets: ["web/styles.css","web/app.js"]
---

## Scope and mode

- Surface: authenticated Pi Remote mobile web client
- Mode: Operate

## Audience and job

- Martin checks one live Pi coding session from a phone while away from the laptop keyboard.
- Primary job: understand current progress, inspect concise tool activity, and respond quickly.

## Task and content

- Show active-branch history, streaming assistant text, compact expandable tool activity, connection/working/queue state, and a fixed composer.
- Follow new output until the user scrolls away; then preserve reading position and offer a jump-to-latest control.

## Constraints

- Static HTML, CSS, and JavaScript with no frontend build step.
- Independently rendered semantic events only; never mirror ANSI terminal output or drafts.
- Touch-first, safe-area aware, accessible, resilient to reconnects, and token-authenticated over Tailscale.

## Chosen direction

- Category standard, played straight at the craft level of ChatGPT and Claude mobile.
- Calm, highly readable conversation; familiar controls; restrained borders and state treatment.
- No novelty metaphor, fake terminal, neon operations console, or decorative dashboard chrome.

## Memorable moment

- The route-state header makes the independence explicit in one glance: laptop and phone are both online renderers of the same Pi session, without sharing geometry.

## Open decisions

- None for the core-session release.
