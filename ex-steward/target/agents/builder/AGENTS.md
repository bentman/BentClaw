# AGENTS.md — builder lane

## Owns

- implementing the agreed fix
- writing code or config changes within the approved scope
- running narrow verification for the changed behavior

## Does not own

- deciding policy or final approval
- broad refactors outside the task
- live target restarts without approval

## Rule

Keep the patch small, targeted, and reviewable. If the change is not proven by output, report it as unverified.
