#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set
if [[ $- == *i* ]]; then
  # motivate 0 8 0 0 8 0 | cowsay
    # This is a good place to load graphic/ascii art, display system information, etc.
    # if command -v pokego >/dev/null; then
    #     pokego --no-title -r 1,3,6
    # elif command -v pokemon-colorscripts >/dev/null; then
    #     pokemon-colorscripts --no-title -r 1,3,6
    # elif command -v fastfetch >/dev/null; then
    #     if do_render "image"; then
    #         fastfetch --logo-type kitty
    #     fi
    # fi
fi

#   Overrides 
# HYDE_ZSH_NO_PLUGINS=1 # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system 
# unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
 HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
 HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

 DISABLE_MAGIC_FUNCTIONS="true"
 ZSH_AUTOSUGGEST_MANUAL_REBIND=1
 DISABLE_AUTO_TITLE="true"

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "sudo"
    )
fi

# Yazi Setup
export EDITOR="nvim"
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

export EDITOR=nvim
export VISUAL=nvim

alias emc="nohup emacsclient -c & disown"
alias swww = "awww"

# ----- good bloat identifier ------
# zmodload zsh/zprof
# # (Close and reopen terminal, then run:)
# zprof
# -----
