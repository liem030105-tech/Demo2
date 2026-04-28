---
description: Generate `.cursor/rules/*.mdc` and `AGENTS.md` using the ai-project-rules-generator workflow (vendored into this repo).
---

# AI Project Rules Generator (vendored)

## What this skill is

This folder vendors the workflow from `naravid19/ai-project-rules-generator` so you can run it directly inside this workspace to generate:

- `.cursor/rules/*.mdc` (or `.cursorrules` depending on your preference)
- `AGENTS.md`
- optional `.rulesrc.yaml` (configuration)

## How to use

1) Open the workflow:

- `skills/ai-project-rules-generator/workflows/create-project-rules.md`

2) Follow it from Stage 0 → Stage 5.

## Notes

- Upstream repo: `https://github.com/naravid19/ai-project-rules-generator`
- Workflow source (raw): `https://raw.githubusercontent.com/naravid19/ai-project-rules-generator/main/workflows/create-project-rules.md`
- Config template: `skills/ai-project-rules-generator/templates/rulesrc-template.yaml`

