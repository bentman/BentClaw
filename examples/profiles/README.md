# Hermes profile examples

Example configurations for three specialist assistants:

- **E.D.I.T.H.** — independent review and quality control.
- **F.R.I.D.A.Y.** — research, documents and analysis.
- **J.A.R.V.I.S.** — coding and testing.

Use them as starting points and adapt the models, role instructions and optional services to your needs.

## Contents

Each profile directory contains:

| File | Purpose |
|---|---|
| `SOUL.md` | Personality and role instructions |
| `profile.yaml` | Profile description and display title |
| `config.yaml` | Model, tools, plugins, voice and MCP settings |
| `.env.example` | Commented credential placeholders |

## Requirements

Install [Hermes Agent](https://hermes-agent.nousresearch.com/docs/) and arrange access to your chosen model provider. The example model names are configurable, not requirements.

The Claude configurations use the experimental DirectSDK plugin, which requires Claude Code and a compatible Anthropic account. Choose another provider if you do not need that integration. For separate Claude credentials, follow the plugin's `claude_config_dir` guidance; Hermes's `auth.adopt_external_logins` setting does not isolate the Claude subprocess.

Optional services include ElevenLabs for speech and the Context7 and Microsoft Learn MCP servers for documentation lookup. Enable only what you need. Context7 key authentication also requires the header setting shown in `config.yaml`.

## Getting started

1. Create a fresh profile through Hermes Desktop or `hermes profile create NAME`. Use `hermes profile show NAME` to locate its directory.
2. Copy the chosen example's `SOUL.md`, `profile.yaml` and `config.yaml` into that directory. Back up an existing profile before replacing its files.
3. Review the role instructions and settings. Select an available model, configure authentication and install any plugins the configuration uses.
4. If needed, copy `.env.example` to `.env` and fill in only the credentials you use. Do not overwrite existing credentials or commit secrets.
5. Check the configuration, then open the profile in Desktop or start a CLI chat.

Hermes supplies bundled skills. Browse its skill and plugin catalogs for additional capabilities; `antigravity-cli` is an optional skill for working with that CLI. The examples already contain the two MCP server definitions, so you do not need to add them again.

## Basic commands

Replace `NAME` with your profile name. Use `--help` on any subcommand for its available options.

```bash
hermes profile list
hermes -p NAME model
hermes -p NAME config check
hermes -p NAME skills list
hermes -p NAME plugins list
hermes -p NAME mcp list
hermes -p NAME chat
```

## Documentation and support

These files are configuration examples, not a separate agent product. For installation, authentication, compatibility and troubleshooting, consult the component maintainers:

- **Hermes Agent / Nous Research:** [documentation](https://hermes-agent.nousresearch.com/docs/), [profiles guide](https://hermes-agent.nousresearch.com/docs/user-guide/profiles/), [support and issues](https://github.com/NousResearch/hermes-agent/issues).
- **Hermes plugins:** [official plugin repository and integration instructions](https://github.com/NousResearch/hermes-official-plugins).
- **Claude Code / Anthropic:** [documentation](https://code.claude.com/docs/).
- **Context7 / Upstash:** [documentation and support](https://github.com/upstash/context7).
- **Microsoft Learn MCP:** [documentation](https://learn.microsoft.com/training/support/mcp).
- **ElevenLabs:** [documentation and support](https://elevenlabs.io/docs/overview).
