# Hermes profile examples: E.D.I.T.H., F.R.I.D.A.Y., J.A.R.V.I.S.

Minimal, secret-free definitions of three specialist Hermes profiles, extracted read-only from a working
BentClaw host (Hermes Agent v0.23.0 / 2026.9.24). Each directory holds only what defines the profile:

| File | Purpose |
|---|---|
| `SOUL.md` | Persona and operating rules (copied verbatim from the live profile) |
| `config.yaml` | Model, toolsets, TTS voice, plugin, MCP servers (settings only, no secrets) |
| `profile.yaml` | Description (used by the Kanban decomposer) and Bot Mode title |
| `.env.example` | Names of optional secrets, all commented out. Copy to `.env` and fill in yourself |

| Profile | Role | Model (provider) |
|---|---|---|
| `edith` 🛡️ | Independent verification, QC, correction requests | `gpt-6.1-sol` (`openai-codex`) |
| `friday` 🔎 | Research, documents, analysis, bounded execution | `claude-sonnet-5-5[1m]` (DirectSDK) |
| `jarvis` 🤖 | Coding, debugging, testing, implementation | `claude-opus-5-5[1m]` (DirectSDK) |

Model ids are preserved exactly as used on the source host. Whether they exist for you depends on your
accounts; change them with `hermes -p NAME model` if not.

**Not included:** the `tacocat` default profile (the coordinator the personas refer to), memories, sessions,
auth state, cron routines, caches, backups, avatars, and the `moa` / fallback settings (fallbacks are
present but commented out in `config.yaml`).

## Concepts to keep straight

- A **profile** is a directory `<HERMES_HOME>/profiles/<name>/` with its own config, memory, skills and
  credentials. It is **not** an OS sandbox: every profile runs as your user and can touch the same files.
- A **Bot** is the same profile seen through Desktop Bot Mode (roster, one canonical Bot Chat, routines).
  `profile.yaml` carries the metadata Desktop reads (`ui_meta.hermes-bots`); the roster entry and Bot Chat
  are created/shown by Desktop, not by copying files.
- Anonymous children spawned with `delegate_task` are temporary workers, **not** named Bots.
- These examples add no orchestration layer. They assume a separate coordinator profile (`tacocat` on the
  source host); without one, the "return the result to tacocat" lines in `SOUL.md` are just wording and you
  may edit them.

## Prerequisites

- Hermes installed (`hermes --version`). Written against v0.23.0; `plugins`, `mcp`, `profile` flags below were
  checked against that version's `--help`.
- For `friday` and `jarvis`: Claude Code CLI (`npm install -g @anthropic-ai/claude-code`, observed 2.1.311) and a
  Claude Pro/Max subscription. For `edith`: a ChatGPT/Codex login for the `openai-codex` provider.
- Network access to `mcp.context7.com` and `learn.microsoft.com` for the MCP servers.

## 1. Create the profiles safely

Fresh profiles, not `--clone`, so no secrets or state are copied from anywhere. **Setup only ever touches
profiles this run creates.** If a target name already exists it is skipped entirely (no config copy, no
migration, no `.env` change), so its settings and credentials stay byte-for-byte intact. Run from the
repository root.

```bash
set -eu
SRC="$PWD/examples/profiles"
CREATED=""
for p in edith friday jarvis; do
  if hermes profile list 2>/dev/null | grep -qw "$p"; then
    echo "SKIP $p: profile already exists (left untouched)"; continue
  fi
  hermes profile create "$p" --no-alias            # keeps bundled skills; add --no-skills for an empty profile
  # Keep the whole path (it may contain spaces): strip only the "Path:" label.
  d="$(hermes profile show "$p" 2>/dev/null | sed -n 's/^Path: *//p')"
  case "$d" in */"$p") ;; *) echo "unexpected profile path for $p: '$d'" >&2; exit 1 ;; esac
  [ -d "$d" ] || { echo "profile dir missing for $p: '$d'" >&2; exit 1; }
  # Definition files, plus the all-commented secrets template as .env (replaces only the fresh scaffold).
  cp "$SRC/$p/SOUL.md" "$SRC/$p/config.yaml" "$SRC/$p/profile.yaml" "$d/"
  cp "$SRC/$p/.env.example" "$d/.env" && chmod 600 "$d/.env"
  # The examples omit _config_version so Hermes can migrate them to the installed schema.
  hermes -p "$p" config migrate
  CREATED="$CREATED $p"
done
echo "created:${CREATED:- (none)}"
```

(`config migrate` may print optional-variable hints and ask "Configure new keys? [y/N]"; answer `N`. Unattended
it defaults to no.) (`profile create` takes `--description`; `profile.yaml` already sets it. To change it later:
`hermes profile describe NAME --text "..."`.)

To re-apply an example to an **existing** profile, do it by hand after backing up (e.g.
`cp "$d/config.yaml" "$d/config.yaml.bak"`); nothing above does that for you. Never overwrite a `.env`
that holds real values.

> Using a non-default `HERMES_HOME` only moves the profile *home*; profile lookup can still resolve against
> `~/.hermes`. To rehearse safely, also set `HOME` to a scratch directory (this is how these files were tested).

## 2. Secrets (all optional)

Step 1 put a comment-only copy of `.env.example` at `<profile dir>/.env` in each **new** profile (find the
directory with `hermes profile show NAME`). Edit it, uncomment only what you use, paste values locally, never
commit it. Profiles that already existed were not touched; edit their own `.env` by hand.

| Variable | Needed for | Required? |
|---|---|---|
| `ELEVENLABS_API_KEY` | TTS (`tts.provider: elevenlabs`) / Bot voice | Only if you use speech |
| `TAVILY_API_KEY` | Tavily-backed web search | Optional |
| `CONTEXT7_API_KEY` | Higher Context7 limits | Optional; **inert unless you enable the `headers:` block (section 6)** |
| `GEMINI_API_KEY` | `gemini` fallback provider | Only if you enable that fallback |

Lines are commented out deliberately: a blank `KEY=` can shadow a value inherited from your shell. Model auth
is not in `.env` (see next section). The repo's `.gitignore` ignores `.env` and keeps `.env.example`.

## 3. Model authentication

- **`edith` (`openai-codex`)**: `hermes -p edith auth add openai-codex` (interactive login). Confirm with
  `hermes -p edith model`.
- **`friday`, `jarvis` (DirectSDK, below)**: they log in through the `claude` CLI, not Hermes `auth`.

## 4. Plugins

Actually configured on all three live profiles: **one non-bundled plugin**, `claude-subscription-directsdk-experimental`
v0.3.4 (catalog `official`, repo `NousResearch/hermes-official-plugins`, pinned commit `83f0a896`). Its
`plugin.yaml` lists the external dependency `claude` and `claude --version` as the check. It is enabled on `edith`
too, because `edith`'s live fallback pointed at it. Bundled plugins (browser, platforms, image-gen, etc.) ship with
Hermes and were left at their defaults; they are not listed here. Compact check of non-bundled ones:
`hermes -p NAME plugins list --plain --no-bundled`.

```bash
npm install -g @anthropic-ai/claude-code && claude --version     # dependency
hermes plugins search claude-subscription                         # shows catalog name + pin
hermes -p friday plugins install claude-subscription-directsdk --enable
hermes -p jarvis plugins install claude-subscription-directsdk --enable
# edith: optional; only needed if you restore the DirectSDK fallback
```

`install` may ask for dependency consent (`--yes-deps` answers it for you; `--no-enable` installs disabled).
The installed plugin id carries the `-experimental` suffix, which is what `config.yaml` references.

### Isolating the Claude login (do this before first use)

`auth.adopt_external_logins: false` stops Hermes adopting external logins, but it **does not isolate** the
`claude` subprocess DirectSDK starts: that process uses `CLAUDE_CONFIG_DIR` from the environment or, absent
that, your normal `~/.claude` login. On the source host the plugin setting `claude_config_dir` was unset, so
the profiles shared the host's default Claude login. To give a profile its own login without touching the host's:

```bash
CD="$HOME/.claude-profiles/friday"          # any absolute path you choose
mkdir -p "$CD" && chmod 700 "$CD"
CLAUDE_CONFIG_DIR="$CD" claude auth login   # interactive; affects only $CD
CLAUDE_CONFIG_DIR="$CD" claude auth status
hermes -p friday config set \
  plugins.entries.claude-subscription-directsdk-experimental.settings.claude_config_dir "$CD"
```

The `config.yaml` examples show the same key as a commented placeholder
(`<ABSOLUTE_PATH_TO_CLAUDE_CONFIG_DIR>`). Never run `claude auth logout` for this; it would log out the host. One
subscription still shares one usage window however many directories are used.

## 5. Skills

All three live profiles have the same set: Hermes's **40 bundled skills** (installed automatically by
`profile create`, source `builtin`) plus **one hub skill**, `antigravity-cli` (source `official`,
identifier `official/autonomous-ai-agents/antigravity-cli`). There are **no custom/local skills**, so nothing is
vendored here. The antigravity skill is optional; the personas do not depend on it.

```bash
hermes -p friday skills list                                    # what you have
hermes skills search antigravity                                # confirm identifier
hermes -p friday skills install official/autonomous-ai-agents/antigravity-cli --yes   # optional
```

## 6. MCP servers

Both servers are remote, configured without credentials, and enabled on all three profiles (already present in
`config.yaml`, so no `mcp add` is needed). To recreate or add them by hand:

```bash
hermes -p friday mcp add context7 --url https://mcp.context7.com/mcp
hermes -p friday mcp add microsoft-learn --url https://learn.microsoft.com/api/mcp
hermes -p friday mcp list
hermes -p friday mcp test context7
```

**Optional Context7 key.** The server works anonymously. `CONTEXT7_API_KEY` in `.env` sends nothing on its
own; Hermes only expands `${VAR}` references that appear in config. To opt in, uncomment the `headers:` block
under `mcp_servers.context7` in the profile's `config.yaml` (`Authorization: "Bearer ${CONTEXT7_API_KEY}"`), or
set it natively (single quotes keep `${...}` literal):

```bash
hermes -p friday config set mcp_servers.context7.headers.Authorization 'Bearer ${CONTEXT7_API_KEY}'
```

Header format follows Context7's upstream docs; confirm with `hermes -p friday mcp test context7` after
putting a real key in `.env`.

Other ids in `hermes mcp catalog` are optional extras and not part of these profiles.

## 7. Validate (no real auth needed)

```bash
for p in edith friday jarvis; do
  hermes -p "$p" config check | head -5       # reports schema/version status
  hermes -p "$p" config get model.default
  hermes -p "$p" mcp list
  hermes -p "$p" plugins list --plain --no-bundled
done
hermes profile list
```

`config check` prints optional-variable hints (`○ ...`); those are informational. A `Config version: 0 → 52`
line before you run `config migrate` is expected.

## 8. Use them

```bash
hermes -p friday chat                       # CLI
hermes -p friday chat -q "Say hello in one line."   # one-shot (spends model quota)
hermes desktop                              # Desktop app; Bot Mode is on by default (Bots tab)
```

In Desktop, a profile appears in the Bots roster, showing the `ui_meta` title from `profile.yaml`; clicking it
opens its single canonical Bot Chat (`/new` becomes `/compact` there). Edit title/description/avatar/SOUL via
right-click → **Edit Profile**; routines are created in the Routines pane and appear in `hermes cron list`.
**Nothing here schedules routines.** Each Bot speaks with its own profile's `tts.*` voice (ElevenLabs voice ids
in the examples are the live ones; they need `ELEVENLABS_API_KEY`). Avatars are `assets/avatar.png` in a live
profile and are not shipped here; add your own via Edit Profile.

The live profiles also use a per-profile Desktop dashboard theme (`dashboard.theme`, files in
`~/.hermes/dashboard-themes/`). Those are global user files, not part of the profile, and are omitted.

## 9. Kanban (optional, not activated by this README)

All three profiles enable the `kanban` toolset. The board is a single SQLite file shared across profiles
(`hermes kanban init` is idempotent) and tasks are assigned by profile name, so the `description` in
`profile.yaml` matters.

```bash
hermes kanban init
hermes kanban assignees          # should list edith, friday, jarvis
hermes kanban create --help      # see flags; assign with the profile name
```

Running tasks needs the Kanban dispatcher; see https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban
and `hermes kanban dispatch --help` before enabling it. Verify dispatcher behavior there rather than assuming it
from this file.

## Sources

Official docs: https://hermes-agent.nousresearch.com/docs (Bot Mode: `/user-guide/bot-mode`). Plugin repo:
https://github.com/NousResearch/hermes-official-plugins.
