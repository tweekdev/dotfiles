# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

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


function current_branch() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo ${ref#refs/heads/}
}

function current_repository() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo $(git remote -v | cut -d':' -f 2)
}

alias fullCheck="yarn test:ci --coverage && yarn lint --fix && yarn typecheck"
alias fullCheckAdmin="cd ~/Developer/travauxlib/admin && yarn test:ci --coverage && yarn lint --fix && yarn typecheck"
alias fullCheckPro="cd ~/Developer/travauxlib/pro && yarn test:ci --coverage && yarn lint --fix && yarn typecheck"
alias fullCheckApp="cd ~/Developer/travauxlib/app && yarn test:ci --coverage && yarn lint --fix && yarn typecheck"
alias fullCheckShared="cd ~/Developer/travauxlib/shared && yarn test:ci --coverage && yarn lint --fix && yarn typecheck"

#alias fullCheck="cd ~/Developer/travauxlib && ./full-check-all.sh "
#alias fullCheckAdmin="cd ~/Developer/travauxlib && ./full-check-all.sh admin"
#alias fullCheckPro="cd ~/Developer/travauxlib && ./full-check-all.sh pro"
#alias fullCheckApp="cd ~/Developer/travauxlib && ./full-check-all.sh app"
#alias fullCheckShared="cd ~/Developer/travauxlib && ./full-check-all.sh shared"

alias check="yarn lint --fix && yarn typecheck"
alias yt="DEBUG_PRINT_LIMIT=50000 yarn test"
alias ytl="yarn test:local"
alias pjt="cd Developer/travauxlib"
alias zshcode="code ~/.zshrc"
alias cat='bat'
alias ls='eza --color=always --long --git --icons=always' #my preferred listing
alias lst='eza --color=always --long --git --icons=always --tree --level=3' #my preferred listing
alias tml='tmux list-sessions'
alias tmkt='tmux kill-session -t'
alias tmk='tmux kill-session'
#alias vim to neovim
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias n='nvim'
alias sn= 'find . -name "*.js" -or -name "*.ts" | entr -r nvim'

# Most used git command should be short.
alias ga='git add'
alias gap='ga --patch'
alias gb='git branch'
alias gba='gb --all'
alias gc='git commit'
alias gca='gc --amend --no-edit'
alias gce='gc --amend'
alias gco='git checkout'
alias gcl='git clone --recursive'
alias gd='git diff --output-indicator-new=" " --output-indicator-old=" "'
alias gds='gd --staged'
alias gi='git init'
alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'
alias gm='git merge'
alias gn='git checkout -b'  # new branch
alias gp='git push'
alias gr='git reset'
alias gs='git status --short'
alias gu='git pull'

alias s='git status -sb'
alias ga='git add -A'
alias gap='ga -p'
alias add="git add -p ."
alias adds="git add ."
alias gst="git status"
alias gcm="git commit -m "
alias push='git push -u origin $(current_branch)'
alias master="git checkout master"
alias masterp="git checkout master && git pull"
alias develop="git checkout develop"
alias developp="git checkout develop && git pull"
alias gcb='git checkout -b'

alias gckm="git checkout -"
alias pull="git pull"
alias gbr='git branch -v'

alias gch='git cherry-pick'

alias gca!='git commit -v -a --amend'


alias gco='git checkout'


alias gd='git diff -M'
alias gd.='git diff -M --color-words="."'
alias gdc='git diff --cached -M'
alias gdc.='git diff --cached -M --color-words="."'

alias gf='git fetch'
alias gfa='git fetch --all'

# Helper function.
git_current_branch() {
  cat "$(git rev-parse --git-dir 2>/dev/null)/HEAD" | sed -e 's/^.*refs\/heads\///'
}

alias glog='git log --date-order --pretty="format:%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar%Creset"'
alias gl='glog --graph'
alias gla='gl --all'

alias gm='git merge --no-ff'
alias gmf='git merge --ff-only'

alias gp='git push'
alias gpthis='gp origin $(git_current_branch)'
alias gpthis!='gp --set-upstream origin $(git_current_branch)'

alias grb='git rebase -p'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'

alias gr='git reset'
alias grh='git reset --hard'
alias grsh='git reset --soft HEAD~'

alias grv='git remote -v'

alias gs='git show'
alias gs.='git show --color-words="."'

alias gsts='git stash'
alias gstsp='git stash pop'

alias gfs='git feature-start '

git_squash() {
  git reset $(git merge-base develop $(git branch --show-current))
  git add -A
  git commit -m "$1"
}

# alias for sbt
alias sbt="sbt -v -mem 2048"

# z
. /opt/homebrew/etc/profile.d/z.sh

# docker
alias d='docker'
alias dc='docker-compose'
alias fuckdocker=' docker run -p 5432:5432 --name hemea-db --restart=always -e POSTGRES_USER=hemea -e POSTGRES_DB=hemea -e POSTGRES_PASSWORD=hemea -d postgres'
alias itdb="docker run -p 5431:5432 --name integration-test-db --restart=always -e POSTGRES_USER=play -e POSTGRES_DB=travauxlib-test -e POSTGRES_PASSWORD=play -d postgres &"



# alias connect db
alias dbprod=' cd ~/Developer/travauxlib/scripts && ./db_connect.js prod'
alias dbdev=' cd ~/Developer/travauxlib/scripts && ./db_connect.js develop'
alias dbrecette=' cd ~/Developer/travauxlib/scripts && ./db_connect.js recette'

alias all='cd ~/Developer/travauxlib && ./start.sh all'
alias main='cd ~/Developer/travauxlib && ./start.sh main'
alias admin='cd ~/Developer/travauxlib && ./start.sh admin'
alias pro='cd ~/Developer/travauxlib && ./start.sh pro'
alias app='cd ~/Developer/travauxlib && ./start.sh app'
alias shared='cd ~/Developer/travauxlib && ./start.sh shared'
alias pdf='cd ~/Developer/travauxlib && ./start.sh pdf'

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

# alias restart scheduler
alias restartscheduler=' curl https://api.hemea.com/api/admin-public/schedulers/start-all -H '\x-schedulers-control-key: N1Os6IBXk3QMdb56ByLY'\'

# alias fzf with nvim
alias vif='nvim $(fzf)'

# fzf
source <(fzf --zsh)

##### TMUX options

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
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"

eval "$(starship init zsh)"

# Added by Windsurf
export PATH="/Users/tweekdev/.codeium/windsurf/bin:$PATH"
