# Default aliases
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias vim='/usr/local/Cellar/vim/8.0.0013/bin/'
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'
alias ll='ls -l'
alias la='ls -a'
alias gs="git status"
alias gp="git pull"
alias gc='git checkout'
alias dclean='docker rmi $( docker images -q -f dangling=true)'

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
