#!/bin/bash
#generate terminfo if they do not already exist
if [[ ! -e ~/.terminfo/s/screen-256color ]]; then
  tic terminfou/terminfo-20120811.src
fi

function make_link(){
  if [[ -h $1 ]]; then
    rm $1
  elif [[ -f $1 ]]; then
    mv $1 $1.bak
  fi
  ln -s $2 $1
}

for file in vim/{vimrc.local,vimrc.bundles.local} zsh/{zshenv,zshrc} tmux/tmux.conf inputrc/inputrc R/{Renviron,Rprofile} perl/perltidyrc;do
  make_link ~/.${file##*/} ~/dotfiles/$file
done

#make dircolors link
make_link ~/.dircolors ~/dotfiles/dircolors/dircolors.ansi-light

git config --global core.excludesfile ~/dotfiles/.gitignore
git config --global user.name "Jim Hester"
git config --global user.email "james.f.hester@gmail.com"

#get all submodules
git submodule init && git submodule update

#install spf13 vim
curl http://j.mp/spf13-vim3 -L -o - | sh
