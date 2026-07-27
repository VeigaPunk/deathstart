# Node.js version manager. Initialize before the interactive-shell guard so
# tools launched through non-interactive Bash also inherit fnm's Node version.
#
# The guard matters under parallel agents. Every `fnm env` call mints a symlink
# in $XDG_RUNTIME_DIR/fnm_multishells and PREPENDS another entry to PATH, and
# fnm never reaps them. Unconditional evaluation therefore leaked 859 symlinks
# and stacked PATH 4-5 multishells deep (with .local/bin repeated 3x), because
# every non-interactive shell -- every agent tool call -- minted a fresh one.
#
# So: interactive shells always initialize fully, which installs the --use-on-cd
# hook they actually need. Non-interactive shells reuse an inherited multishell
# when it still resolves, and only mint one when there is nothing valid to
# inherit. Node stays available everywhere; the leak stops.
if command -v fnm >/dev/null 2>&1; then
  if [[ $- == *i* ]] || [[ ! -x "${FNM_MULTISHELL_PATH:-/nonexistent}/bin/node" ]]; then
    eval "$(fnm env --use-on-cd --shell bash)"
  fi
fi

# If not running interactively, don't do anything.
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Godspeed is a process-level contract: child shells, CLIs, and agent runners
# inherit these exported markers automatically.  Agent-specific roots carry the
# full instruction text; xask additionally injects the literal prompt suffix.
export GODSPEED=1
export GODSPEED_MODE=always
export GODSPEED_DELEGATE_SUFFIX=' | godspeed'
export GODSPEED_EXECUTOR_SUFFIX=' | godspeed-impl'

# opencode: bind a real, predictable port.
#
# Without this, opencode binds a random ephemeral port (e.g. 127.0.0.1:36517).
# The team_mode tmux session manager then computes its target as
# `http://localhost:${OPENCODE_PORT:-4096}`, finds nothing listening on 4096,
# and SILENTLY skips creating the member panes -- team_mode.tmux_visualization
# appears broken while actually being enabled. See opencode issue #3963.
#
# Both halves are required and must agree: OPENCODE_PORT drives the fallback
# URL the session manager dials, --port drives what the server actually binds.
#
# The pin is claimed by the FIRST instance only. Pinning it unconditionally made
# every later concurrent instance die on bind (EADDRINUSE -> ServeError), which
# the TUI surfaces as a blank hang rather than an error. So: pin when the port is
# free, fall back to an ephemeral port when it is already taken.
export OPENCODE_PORT=4096
opencode() {
  case " $* " in
    *" --port "*) command opencode "$@"; return ;;
  esac

  local port="${OPENCODE_PORT:-4096}"
  if (exec 3<>"/dev/tcp/127.0.0.1/${port}") 2>/dev/null; then
    # Port already claimed by another opencode: use an ephemeral port so this
    # instance can still start. team_mode tmux visualization only works in the
    # instance holding ${OPENCODE_PORT}.
    printf '%s\n' "opencode: port ${port} already in use; starting on an ephemeral port (team_mode tmux visualization is inactive here)." >&2
    command opencode "$@"
  else
    command opencode --port "$port" "$@"
  fi
}

# Make an alias for invoking commands you use constantly
# alias p='python'


# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
[[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
# <<< grok installer <<<

# hvm-gemma4 mailbox + HVM4 control plane
[ -f "$HOME/.config/hvm-gemma4/env" ] && . "$HOME/.config/hvm-gemma4/env"
export GROK_AGENT="${GROK_AGENT:-orch}"

. "$HOME/.local/share/../bin/env"

# Read the Docs API token (loaded from secure file)
if [ -r "$HOME/.config/readthedocs/api_token" ]; then
  export RTD_TOKEN="$(tr -d '\n' < "$HOME/.config/readthedocs/api_token")"
  export READTHEDOCS_TOKEN="$RTD_TOKEN"
  export RTD_API_TOKEN="$RTD_TOKEN"
fi

# GitLab CLI (glab) + Duo
if [ -r "$HOME/.config/gitlab/api_token" ]; then
  export GITLAB_TOKEN="$(tr -d '\n' < "$HOME/.config/gitlab/api_token")"
  export GLAB_TOKEN="$GITLAB_TOKEN"
  export GITLAB_HOST="${GITLAB_HOST:-gitlab.com}"
fi
if [ -f "$HOME/.local/share/bash-completion/completions/glab" ]; then
  . "$HOME/.local/share/bash-completion/completions/glab" 2>/dev/null || true
fi
alias duo='glab duo cli'

# GitLab Duo always-on (trial)
export GITLAB_DUO_ENABLED=1
export DUO_CLI_AUTO_RUN=1
# Experimental features are enabled server-side on Ultimate trial groups
