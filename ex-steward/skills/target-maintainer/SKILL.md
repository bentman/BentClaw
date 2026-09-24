# Skill: target maintainer

Use this skill when you need to inspect, update, or recover a managed OpenClaw target.

## When to use

- updating the target instance
- diagnosing runtime issues
- repairing config drift
- validating a target rollout

## Procedure

1. Read the current target status and config.
2. Confirm the target host, profile, and repo before any mutation.
3. Back up relevant config or state before changing it.
4. Apply the smallest fix that matches the observed issue.
5. Run the narrow verification commands.
6. Record the evidence and any remaining risk.

## Red lines

- do not change live target state without explicit approval
- do not hide failed checks
- do not write secrets into workspace files
- do not claim success without direct evidence
