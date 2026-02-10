# ============================================
# Homebrew (must be FIRST for Apple Silicon)
# ============================================
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  tmux
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# ============================================
# Project aliases (travauxlib)
# ============================================
alias fullCheck="yarn test:ci --coverage && yarn lint --fix && yarn typecheck" # full check
alias fullCheckAdmin="cd ~/Developer/travauxlib/admin && yarn test:ci --coverage && yarn lint --fix && yarn typecheck" # full check admin
alias fullCheckPro="cd ~/Developer/travauxlib/pro && yarn test:ci --coverage && yarn lint --fix && yarn typecheck" # full check pro
alias fullCheckApp="cd ~/Developer/travauxlib/app && yarn test:ci --coverage && yarn lint --fix && yarn typecheck" # full check app
alias fullCheckShared="cd ~/Developer/travauxlib/shared && yarn test:ci --coverage && yarn lint --fix && yarn typecheck" # full check shared

#alias fullCheck="cd ~/Developer/travauxlib/scripts && ./full-check-all.sh "
#alias fullCheckAdmin="cd ~/Developer/travauxlib/scripts && ./full-check-all.sh admin"
#alias fullCheckPro="cd ~/Developer/travauxlib/scripts && ./full-check-all.sh pro"
#alias fullCheckApp="cd ~/Developer/travauxlib/scripts && ./full-check-all.sh app"
#alias fullCheckShared="cd ~/Developer/travauxlib/scripts && ./full-check-all.sh shared"

alias check="yarn lint --fix && yarn typecheck" # check lint and typecheck
alias yt="DEBUG_PRINT_LIMIT=50000 yarn test" # test
alias ytl="yarn test:local" # test local
alias pjt="cd Developer/travauxlib" # project travauxlib

# ============================================
# General aliases
# ============================================
alias zshcode="cursor ~/.zshrc" # open zshrc in cursor
alias cat='bat'
alias ls='eza --color=always --long --git --icons=always'
alias lst='eza --color=always --long --git --icons=always --tree --level=3'

# Tmux
alias tml='tmux list-sessions'
alias tmkt='tmux kill-session -t'
alias tmk='tmux kill-session'

# Neovim
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias n='nvim'
# que fait le -m ?
# -m means multiple files
# --preview="bat --style=numbers --color=always --line-range :500 {}" means preview the file with bat
# --line-range :500 means preview the first 500 lines of the file
# {} means the file to preview
# fzf is a fuzzy finder
# bat is a cat alternative
# nvim is the editor
# vif is a shortcut for nvim with fzf
alias vif='nvim $(fzf -m --preview="bat --style=numbers --color=always --line-range :500 {}")' # open file in nvim with fzf
alias sn='find . -name "*.js" -or -name "*.ts" | entr -r nvim' # open file in nvim with entr

# ============================================
# Git aliases (cleaned - no duplicates)
# ============================================

# Helper function
git_current_branch() {
  cat "$(git rev-parse --git-dir 2>/dev/null)/HEAD" | sed -e 's/^.*refs\/heads\///'
}

# Status
alias s='git status -sb' # status with branch
alias gst="git status" # status

# Add
alias ga='git add -A' # add all changes
alias add="git add -p ." # add changes
alias adds="git add ." # add changes

# Commit
alias gc='git commit' # no message
alias gcm="git commit -m " # commit with message
alias gca='git commit --amend --no-edit' # amend last commit
alias gce='git commit --amend' # amend last commit
alias gca!='git commit -v -a --amend' # amend last commit with changes

# Branch
alias gb='git branch -v' # list branches
alias gba='git branch --all' # list all branches
alias gcb='git checkout -b' # create new branch
alias gco='git checkout' # checkout branch
alias gckm="git checkout -" # checkout branch to last one
alias master="git checkout master" # checkout master branch
alias masterp="git checkout master && git pull" # checkout master branch and pull
alias develop="git checkout develop" # checkout develop branch
alias developp="git checkout develop && git pull" # checkout develop branch and pull

# Push/Pull
alias gp='git push' # push changes
alias gpthis='gp origin $(git_current_branch)' # push changes to origin
alias gpthis!='gp --set-upstream origin $(git_current_branch)' # push changes to origin and set upstream
alias push='git push -u origin $(git_current_branch)' # push changes to origin and set upstream
alias pull="git pull" # pull changes
alias gf='git fetch' # fetch changes
alias gfa='git fetch --all' # fetch all changes

# Diff
alias gd='git diff -M' # diff changes
alias gd.='git diff -M --color-words="."' # diff changes with color words
alias gdc='git diff --cached -M' # diff changes cached
alias gdc.='git diff --cached -M --color-words="."' # diff changes cached with color words
alias gds='git diff --staged' # diff changes staged

# Log
alias glog='git log --date-order --pretty="format:%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar%Creset"' # log changes
alias gl='glog --graph' # log changes graph
alias gla='gl --all' # log changes all

# Show
alias gsh='git show' # show changes
alias gsh.='git show --color-words="."' # show changes with color words

# git flow
alias release-delete="git flow release delete -f " # delete release 
alias hotfix-delete="git flow hotfix delete -f " # delete hotfix 

# Merge/Rebase
alias grbdevelop='git rebase develop' # rebase develop
alias gm='git merge' # merge changes
alias gmf='git merge --ff-only' # merge changes fast forward only
alias grb='git rebase -p' # rebase changes
alias grba='git rebase --abort' # rebase abort
alias grbc='git rebase --continue' # rebase continue
alias grbi='git rebase -i' # rebase interactive

# Reset
alias gr='git reset' # reset changes
alias grh='git reset --hard' # reset changes hard
alias grsh='git reset --soft HEAD~' # reset changes soft HEAD~

# Other git
alias gcl='git clone --recursive'
alias gi='git init'
alias grv='git remote -v'
alias gsts='git stash'
alias gstsp='git stash pop'
alias gch='git cherry-pick'
alias gfs='git feature-start '

git_squash() {
  git reset $(git merge-base develop $(git branch --show-current)) # reset to develop
  git add -A # add all changes
  git commit -m "$1" # commit with message
}

# ============================================
# SBT
# ============================================
alias sbt="sbt -v -mem 2048" # start sbt with memory 2048

# ============================================
# Zoxide (replaces z.sh)
# ============================================
eval "$(zoxide init zsh)" # initialize zoxide

# ============================================
# Docker
# ============================================
alias d='docker' # start docker
alias dc='docker-compose' # start docker compose
alias fuckdocker='docker run -p 5432:5432 --name hemea-db --restart=always -e POSTGRES_USER=hemea -e POSTGRES_DB=hemea -e POSTGRES_PASSWORD=hemea -d postgres' # start docker with postgres
alias itdb="docker run -p 5431:5432 --name integration-test-db --restart=always -e POSTGRES_USER=play -e POSTGRES_DB=travauxlib-test -e POSTGRES_PASSWORD=play -d postgres &" # start docker with postgres for integration test

# ============================================
# Container
# ============================================
alias c='container' # start container
alias ck='container kill' # kill container
alias ckl='container kill all' # kill all containers
alias cl='container list' # list containers
alias cs='container system start' # start container system

# ============================================
# DB connect aliases
# ============================================
alias dbprod='cd ~/Developer/travauxlib/scripts && ./db_connect.js prod' # connect to prod database
alias dbdev='cd ~/Developer/travauxlib/scripts && ./db_connect.js develop' # connect to develop database
alias dbrecette='cd ~/Developer/travauxlib/scripts && ./db_connect.js recette' # connect to recette database

# ============================================
# Project start aliases
# ============================================
alias all='cd ~/Developer/travauxlib/scripts && ./start.sh all' # start all projects
alias main='cd ~/Developer/travauxlib/scripts && ./start.sh main' # start main project
alias admin='cd ~/Developer/travauxlib/scripts && ./start.sh admin' # start admin project
alias pro='cd ~/Developer/travauxlib/scripts && ./start.sh pro' # start pro project
alias app='cd ~/Developer/travauxlib/scripts && ./start.sh app' # start app project
alias shared='cd ~/Developer/travauxlib/scripts && ./start.sh shared' # start shared project
alias pdf='cd ~/Developer/travauxlib/scripts && ./start.sh pdf' # start pdf project
alias stopall='cd ~/Developer/travauxlib/scripts && ./start.sh stop' # stop all projects

# ============================================
# Brewfile
# ============================================
alias brewfile='brew bundle --file=~/.config/dotfiles/Brewfile'
alias brewcheck='brew bundle check --file=~/.config/dotfiles/Brewfile' # check brewfile
alias brewclean='brew bundle cleanup --file=~/.config/dotfiles/Brewfile' # clean brewfile
alias brewdump='brew bundle dump --force --file=~/.config/dotfiles/Brewfile' # dump brewfile

# ============================================
# Sesh sessions
# ============================================
function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions

# ============================================
# Misc
# ============================================
alias restartscheduler='curl https://api.hemea.com/api/admin-public/schedulers/start-all -H '\''x-schedulers-control-key: N1Os6IBXk3QMdb56ByLY'\'''

# fzf
source <(fzf --zsh)

# TMUX options
tsa() {
	status_bar=$(cat $TMUX_SATUS_BAR)
	tmux set-option -g status-right "$1 $status_bar"
	echo "$1 $status_bar" > $TMUX_SATUS_BAR
}

tsd() {
	echo '[#{session_name}]' > $TMUX_SATUS_BAR
	status_bar=$(cat $TMUX_SATUS_BAR)
	tmux set-option -g status-right "$status_bar"
}

# ============================================
# PATH exports
# ============================================
PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"

# ============================================
# Starship prompt (keep near end)
# ============================================
eval "$(starship init zsh)" # initialize starship prompt

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman" # sdkman directory
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh" # sdkman init
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH" # postgresql bin
export PATH="$HOME/.local/bin:$PATH" # local bin
