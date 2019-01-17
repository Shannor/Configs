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


#docker aliases 
alias dps='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
alias dport='docker ps -a --format "table {{.Names}}:\t{{.Ports}}"'
alias dl='docker logs -f'

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="/usr/local/bin:${PATH}"
