# Checkpoint 1 (2026-08-20): fnm is the Node manager.
# Godspeed markers and opencode port-pin are later lanes — do not add them here yet.
#
# Initialize fnm BEFORE the interactive-shell guard so tools launched through
# non-interactive Bash also inherit Node.
#
# The guard matters under parallel agents. Every `fnm env` call mints a symlink
# in $XDG_RUNTIME_DIR/fnm_multishells and PREPENDS another entry to PATH, and
# fnm never reaps them. Unconditional evaluation therefore leaked hundreds of
# symlinks and stacked PATH several multishells deep, because every
# non-interactive shell (every agent tool call) minted a fresh one.
#
# Interactive shells always initialize fully, which installs the --use-on-cd
# hook they actually need. Non-interactive shells reuse an inherited
# multishell when it still resolves, and only mint one when there is nothing
# valid to inherit. Node stays available everywhere; the leak stops.
if command -v fnm >/dev/null 2>&1; then
  if [[ $- == *i* ]] || [[ ! -x "${FNM_MULTISHELL_PATH:-/nonexistent}/bin/node" ]]; then
    eval "$(fnm env --use-on-cd --shell bash)"
  fi
fi

# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Omarchy's rc runs `mise activate`, which prepends shims. Re-front the
# existing fnm multishell so `node` stays fnm's — do not mint a second one.
if [[ -n "${FNM_MULTISHELL_PATH:-}" && -x "${FNM_MULTISHELL_PATH}/bin/node" ]]; then
  PATH="${FNM_MULTISHELL_PATH}/bin:${PATH}"
fi

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
[[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
# <<< grok installer <<<
