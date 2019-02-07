# Default aliases
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'
alias ll='ls -l'
alias la='ls -a'
alias gs="git status"
alias gp="git pull"
alias gc='git checkout'

[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

#docker aliases 
alias dps='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
alias dport='docker ps -a --format "table {{.Names}}:\t{{.Ports}}"'
alias dl='docker logs -f'
alias drma='docker rm -f $(docker ps -aq)'
alias dpa='docker system prune -a --volumes'

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export PATH="/usr/local/bin:${PATH}" # Use my homebrew version of bin
