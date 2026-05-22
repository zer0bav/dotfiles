# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Load OS-specific plugins dynamically
if [[ "$OSTYPE" == "linux-gnu"* && -f /etc/arch-release ]]; then
    plugins+=(archlinux)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    plugins+=(macos)
fi

# Disable insecure directories verification warning
ZSH_DISABLE_COMPFIX="true"

source $ZSH/oh-my-zsh.sh

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux

# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
#pokemon-colorscripts --no-title -s -r #without fastfetch
#pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -

# fastfetch. Will be disabled if above colorscript was chosen to install
#fastfetch
# Set-up icons for files/directories in terminal using lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

# Load Powerlevel10k config if present.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh && -f ~/lyne-dots/zsh/.p10k.zsh ]] && source ~/lyne-dots/zsh/.p10k.zsh

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

#if [[ $- == *i* ]]; then
 #   if [[ "$TERM_PROGRAM" != "vscode" ]]; then
  #      if [[ -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
   #         exec tmux new-session -A -s workspace
    #    fi
 #   fi
#fi
