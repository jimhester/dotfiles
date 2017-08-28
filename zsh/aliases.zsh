#htop crashes if term is not xterm
alias htop="TERM=xterm htop"
alias l='ls -lhtcr --color=auto'
alias lc='ls -lhtcr --color=auto'
alias lk='ls -lhSr' # sort by size
alias la='ls -ac --color=auto'
alias ll='ls -lah --color=auto'
alias lsd='ls -d */'
alias le='less'
alias ht='htop'
alias g="grep --color=always"
alias gi="grep -i --color=always"
alias cp='cp -a'
alias awkt='awk -F"\t" -v OFS="\t"' #use tab for input and output seperator
alias xm='xmessage -nearmouse DONE'
alias td='todo.sh add'
alias gl="git log --stat"

#sort using a hash or sorted uniq
alias U="awk '!a[\$0]++'"
alias UC="awk '{a[\$0]++}END{ for(key in a){ print key, a[key] } }'"
alias SU='(sort | uniq)' #the grouping parenthesis are to allow you to pipe into the combined command using stdin
alias H='head'
alias T='tail'
alias LC='wc -l'
alias B='tail -n +2'
alias NUL='/dev/null'

alias vi='vim'
