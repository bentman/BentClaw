# MEMORY.md

## Durable facts

- The steward instance is the control-plane operator.
- The target instance is a separate OpenClaw deployment used for multi-agent code work.
- `AGENTS.md` is the operating contract.
- `SOUL.md` is persona and tone.
- `USER.md` holds active directives.
- `memory/YYYY-MM-DD.md` holds daily logs and raw context.
- Long-form procedures belong in `skills/<name>/SKILL.md`.

## Working decisions

- Keep the steward and target responsibilities separate.
- Route work by explicit lane: coordinator, builder, reviewer.
- Require evidence for completion.
- Treat live config edits as approval-gated work.
