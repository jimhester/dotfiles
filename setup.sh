#!/bin/bash

function backup(){
  if [[ -h $1 ]]; then
    rm $1
  elif [[ -f $1 ]]; then
    mv $1 $1.bak
  fi
}
backup ~/.vim;ln -s ~/dotfiles/vim ~/.vim
backup ~/.vimrc;ln -s ~/dotfiles/vim/vimrc ~/.vimrc
backup ~/.zshenv;ln -s ~/dotfiles/zsh/zshenv ~/.zshenv
backup ~/.zshrc;ln -s ~/dotfiles/zsh/zshrc ~/.zshrc
backup ~/.tmux.conf;ln -s ~/dotfiles/tmux/tmux.conf ~/.tmux.conf
backup ~/.inputrc;ln -s ~/dotfiles/input/inputrc ~/.inputrc
backup ~/.Renviron;ln -s ~/dotfiles/R/Renviron ~/.Renviron
backup ~/.Rprofile;ln -s ~/dotfiles/R/Rprofile ~/.Rprofile
backup ~/.perltidyrc; ln -s ~/dotfiles/perl/perltidyrc ~/.perltidyrc

git config --global core.excludesfile ~/dotfiles/.gitignore
git config --global user.name "Jim Hester"
git config --global user.email "james.f.hester@gmail.com"
