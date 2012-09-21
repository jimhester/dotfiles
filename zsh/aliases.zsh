#htop crashes if term is not xterm
alias htop="TERM=xterm htop"
alias lc='ls -lhtcr --color=auto'
alias lk='ls -lhSr' # sort by size
alias la='ls -ac --color=auto'
alias ll='ls -lah --color=auto'
alias lsd='ls -d */'
alias g="grep --color=always"
alias gi="grep -i --color=always"
alias cp='cp -a'
alias -g awkt='awk -v OFS="\t"' #This needs to be global to allow insertion into pipes
#functions
if [ -n "$PS1" ] ; then
  rm () 
  { 
      ls -FCsd "$@"
      echo 'remove[ny]? ' | tr -d '\012' ; read
      if [ "_$REPLY" = "_y" ]; then
          /bin/rm -rf "$@"
      else
          echo '(cancelled)'
      fi
  }
fi
