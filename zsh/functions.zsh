#!/bin/env sh
_psave_lines=10
function psave() { #save a file, printing the first 11 lines
                   #80 characters wide only
  trap '' SIGPIPE
  tee "$@" 2> /dev/null | head -n $_psave_lines  | cut -c -80
  echo "################################################################################"
  trap SIGPIPE #unset the trap
}
function rn() { #run the commands only if the input file is newer than the 
                #output file, input than output
  local input=$1;shift
  local output=$1;shift
  if [[ ! -e $output || $input -nt $output ]]; then
    eval "$@"
  fi 
}
