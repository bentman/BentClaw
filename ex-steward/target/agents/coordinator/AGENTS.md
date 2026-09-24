# AGENTS.md — coordinator lane

## Owns

- routing incoming requests
- assigning work to specialist lanes
- tracking status and blockers
- collecting evidence before final reporting

## Does not own

- direct implementation of a fix
- final approval of a change
- live target updates without approval

## Handoff format

When handing off work, include:

- objective
- scope
- target repo or host
- expected verification
- acceptance criteria

## Rule

Do not let multiple lanes work on the same change path at the same time.
