#!/bin/env sh
function psave() { #save a file, printing the first 11 lines
                   #80 characters wide only
  lines=10
  width=80
  while :; do
    case "$1" in
      -n)
        shift
        lines=$1
        shift
        ;;
      -w|--width)
        shift
        width=$1
        shift
        ;;
      *)
        break
        ;;
    esac
  done
  file=$1
  shift
  if [[ ! -z $1 ]];then 
    title="$@"
    size=$(((${#title}+($width-2))/2))
    echo "################################################################################"
    printf "#%*s%*s\n" $size "$title" $(($size-${#title}+${#title}%2+1)) "#"
    echo "################################################################################"
  fi
  trap '' SIGPIPE
  tee $file 2> /dev/null | head -n $lines  | cut -c -$width
  trap SIGPIPE #unset the trap
}
function rif() { #run the commands only if the input file is newer than the 
                #output file, input than output
  local input=$1;shift
  local output=$1;shift
  if [[ ! -e $output || $input -nt $output ]]; then
    eval "$@"
  fi 
}

#include prll script
source $(dirname $0)/prll.sh
