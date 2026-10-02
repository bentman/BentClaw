#!/usr/bin/env bash
set -Eeuo pipefail
die() { printf '%s\n' "$*" >&2; exit 1; }
ENV_FILE=linux/.env.example
openclaw_user= openclaw_pswd=
declare -A seen=()
declare -A CLI_INSTALLS=()
CLI_ORDER=()
while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
    [[ $line == *=* ]] || die 'Expected KEY=value in configuration.'
    key=${line%%=*}; value=${line#*=}
    key=${key#"${key%%[![:space:]]*}"}; key=${key%"${key##*[![:space:]]}"}
    if [[ $value == \"*\" || $value == \'*\' ]]; then value=${value:1:${#value}-2}; fi
    [[ $key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || die 'Invalid configuration key.'
    [[ ! ${seen[$key]+present} ]] || die "Duplicate configuration key: $key."
    seen[$key]=1
    case $key in
        openclaw_user|openclaw_pswd|NODE_MAJOR|REPO_URL) printf -v "$key" '%s' "$value" ;;
        PACKAGES|DEB_PACKAGES|RPM_PACKAGES|ARCH_PACKAGES|PYTHON_PACKAGES)
            IFS=' ' read -r -a "$key" <<< "$value"
            ;;
        CLI_*) CLI_INSTALLS[$key]=$value; CLI_ORDER+=("$key") ;;
        *) die "Unknown configuration key: $key." ;;
    esac
done < "$ENV_FILE"
for key in openclaw_user openclaw_pswd PACKAGES DEB_PACKAGES RPM_PACKAGES ARCH_PACKAGES PYTHON_PACKAGES NODE_MAJOR REPO_URL; do
    [[ ${seen[$key]+present} ]] || die "Missing $key; copy the corresponding setting from linux/.env.example."
done
[[ $NODE_MAJOR =~ ^[1-9][0-9]*$ ]] || die 'NODE_MAJOR must be a positive integer.'
[[ ${#CLI_ORDER[@]} -gt 0 ]] || die 'Add CLI_ entries from linux/.env.example.'
for key in "${CLI_ORDER[@]}"; do
    record=${CLI_INSTALLS[$key]}
    separators=${record//[^|]/}
    [[ ${#separators} == 4 ]] || die "$key requires five pipe-separated fields."
    IFS='|' read -r cli cli_shell cli_url cli_env cli_args <<< "$record"
    [[ $cli =~ ^[a-z][a-z0-9_-]*$ ]] || die "$key requires a plain command name."
    [[ $cli_shell == bash || $cli_shell == sh ]] || die "$key shell must be bash or sh."
    [[ $cli_url == https://* && $cli_url != *[[:space:]]* ]] || die "$key requires an HTTPS installer URL."
    env_args=()
    IFS=' ' read -r -a env_args <<< "$cli_env"
    for assignment in "${env_args[@]}"; do
        [[ $assignment =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]] || die "$key has an invalid environment assignment."
    done
done
[[ $openclaw_user =~ ^[a-z_][a-z0-9_-]{0,31}$ && $openclaw_user != root ]] || die 'Use a non-root Linux username (lowercase, maximum 32 characters).'
[[ -n $openclaw_pswd && $openclaw_pswd != *:* ]] || die 'Password must be nonempty and cannot contain a colon.'


[[ ${#CLI_ORDER[@]} == 5 ]]
[[ ${CLI_INSTALLS[CLI_antigravity]} == agy* ]]
printf 'Configuration validation passed\n'
