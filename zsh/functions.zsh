#!/bin/env sh
_psave_lines=10
function psave() { #save a file, printing the first 11 lines
  trap '' SIGPIPE
  tee "$@" 2> /dev/null | head -n $_psave_lines  
}
