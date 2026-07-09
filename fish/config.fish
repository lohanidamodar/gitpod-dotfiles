## Set environment
set TERM "xterm-256color"
set EDITOR "micro"
set VISUAL "kate"
set fish_greeting

## Ensure user-local install dirs are on PATH.
## Official installers (claude, bun, cargo, flutter, dart) drop binaries in
## these; keep them here rather than in fish_variables so PATH never depends
## on a stale universal $PATH captured on some other machine. Prepend so the
## native tools win over any Windows .exe shims inherited via WSL interop.
for dir in $HOME/.local/bin $HOME/.bun/bin $HOME/.cargo/bin $HOME/flutter/bin $HOME/dart-sdk/bin
    if test -d $dir; and not contains $dir $PATH
        set -gx PATH $dir $PATH
    end
end


## Lambda theme https://github.com/hasanozgan/theme-lambda
function fish_prompt
  # Cache exit status
  set -l last_status $status

  # Just calculate these once, to save a few cycles when displaying the prompt
  if not set -q __fish_prompt_hostname
    # Use fish's built-in $hostname (fish >= 3.2) so we don't depend on the
    # `hostname` binary, which isn't installed on a minimal Arch/WSL system.
    if set -q hostname
      set -g __fish_prompt_hostname (string split -f1 . -- $hostname)
    else if type -q prompt_hostname
      set -g __fish_prompt_hostname (prompt_hostname)
    else
      set -g __fish_prompt_hostname (uname -n | cut -d . -f 1)
    end
  end
  if not set -q __fish_prompt_char
    switch (id -u)
      case 0
	set -g __fish_prompt_char '#'
      case '*'
	set -g __fish_prompt_char 'λ'
    end
  end

  # Setup colors
  #use extended color pallete if available
#if [[ $terminfo[colors] -ge 256 ]]; then
#    turquoise="%F{81}"
#    orange="%F{166}"
#    purple="%F{135}"
#    hotpink="%F{161}"
#    limegreen="%F{118}"
#else
#    turquoise="%F{cyan}"
#    orange="%F{yellow}"
#    purple="%F{magenta}"
#    hotpink="%F{red}"
#    limegreen="%F{green}"
#fi
  set -l normal (set_color normal)
  set -l white (set_color FFFFFF)
  set -l turquoise (set_color 5fdfff)
  set -l orange (set_color df5f00)
  set -l hotpink (set_color df005f)
  set -l blue (set_color blue)
  set -l limegreen (set_color 87ff00)
  set -l purple (set_color af5fff)
 
  # Configure __fish_git_prompt
  set -g __fish_git_prompt_char_stateseparator ' '
  set -g __fish_git_prompt_color 5fdfff
  set -g __fish_git_prompt_color_flags df5f00
  set -g __fish_git_prompt_color_prefix white
  set -g __fish_git_prompt_color_suffix white
  set -g __fish_git_prompt_showdirtystate true
  set -g __fish_git_prompt_showuntrackedfiles true
  set -g __fish_git_prompt_showstashstate true
  set -g __fish_git_prompt_show_informative_status true 

  set -l current_user (whoami)

  # Line 1
  echo -n $white'╭─'$hotpink$current_user$white' at '$orange$__fish_prompt_hostname$white' in '$limegreen(pwd|sed "s=$HOME=⌁=")$turquoise
  __fish_git_prompt " (%s)"
  echo

  # Line 2
  echo -n $white'╰'
  # support for virtual env name
  if set -q VIRTUAL_ENV
      echo -n "($turquoise"(basename "$VIRTUAL_ENV")"$white)"
  end
  echo -n $white'─'$__fish_prompt_char $normal
end

# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

## Fish command history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

## Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
	set from (echo $argv[1] | trim-right /)
	set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

## Useful aliases
# Prefer eza/exa when available, otherwise fall back to plain ls so these
# never break a shell where exa was skipped (e.g. this Arch/WSL setup).
if type -q eza
    alias ls='eza -al --color=always --group-directories-first'
    alias la='eza -a --color=always --group-directories-first'
    alias ll='eza -l --color=always --group-directories-first'
    alias lt='eza -aT --color=always --group-directories-first'
else if type -q exa
    alias ls='exa -al --color=always --group-directories-first'
    alias la='exa -a --color=always --group-directories-first'
    alias ll='exa -l --color=always --group-directories-first'
    alias lt='exa -aT --color=always --group-directories-first'
else
    alias ls='ls --color=auto'
    alias la='ls -A --color=auto'
    alias ll='ls -alh --color=auto'
    alias lt='ls -R --color=auto'
end

alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias upd='sudo reflector --latest 5 --age 2 --fastest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist && cat /etc/pacman.d/mirrorlist && sudo pacman -Syu && fish_update_completions'
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

## Import colorscheme from 'wal' asynchronously
if type "wal" >> /dev/null 2>&1
   cat ~/.cache/wal/sequences
end

## Git alias
alias gff='git flow feature'
alias gfr='git flow release'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git log --oneline --graph --decorate --all'

## Docker
alias dc="docker compose"
alias dce="docker compose exec"
alias dcea="docker compose exec appwrite"
alias dcfr="docker compose up -d --force-recreate"
alias dcl="docker compose logs -f"
alias dcb="docker compose build"
alias dcdl="docker compose down --rmi all --volumes --remove-orphans"

## Docker login script
alias dclo="~/.dotfiles/scripts/docker_login.sh"

## appwrite redis
alias aprf="~/.dotfiles/scripts/redis_flushall.sh"

## composer
alias cinst="composer install --ignore-platform-reqs"
alias cupdt="composer update --ignore-platform-reqs"
alias cfmt="composer format"

## appwrite cloud init
alias acinit="dclo && cinst && composer format && dc build appwrite && dc up -d && dc logs -f appwrite"