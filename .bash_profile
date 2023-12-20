# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
if [ -e /home/gitpod/.nix-profile/etc/profile.d/nix.sh ]; then . /home/gitpod/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

## Git
alias gco="git checkout"
alias gsh="git stash"

## docker
alias dc="docker compose"
alias dce="docker compose exec"
alias dcea="docker compose exec appwrite"
alias dcfr="docker compose up -d --force-recreate"

# #directory
# alias ls='exa -al --color=always --group-directories-first' # preferred listing
# alias la='exa -a --color=always --group-directories-first'  # all files and dirs
# alias ll='exa -l --color=always --group-directories-first'  # long format
# alias lt='exa -aT --color=always --group-directories-first' # tree listing
