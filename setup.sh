#!/bin/bash
#generate terminfo if they do not already exist
mkdir -p ~/.terminfo/s/
if [[ ! -e ~/.terminfo/s/screen-256color ]]; then
  tic terminfou/terminfo-20120811.src
fi

function make_link(){
  #make parent directories
  mkdir -p ${1%/*}
  if [[ -h $1 ]]; then
    rm $1
  elif [[ -f $1 ]]; then
    mv $1 $1.bak
  fi
  ln -s $2 $1
}

#dotfiles
for file in \
    vim/{vimrc.local,vimrc.bundles.local} \
    zsh/{zshenv,zshrc} \
    tmux/tmux.conf \
    inputrc/inputrc \
    R/{Renviron,Rprofile} \
    perl/perltidyrc;do
  make_link ~/.${file##*/} ~/dotfiles/$file
done

#shared files
for file in knitr_bootstrap/knitr_bootstrap.{css,html};do
  make_link ~/share/${file##*/} ~/dotfiles/$file
done

#make dircolors link
make_link ~/.dir_colors ~/dotfiles/dircolors/dircolors.ansi-light

#make colemak directory
make_link ~/.colemak ~/dotfiles/colemak/

git config --global core.excludesfile ~/dotfiles/.gitignore
git config --global user.name "Jim Hester"
git config --global user.email "james.f.hester@gmail.com"

#install spf13 vim
if [[ ! -e ~/.spf13-vim-3/ ]]; then
  curl http://j.mp/spf13-vim3 -L -o - | sh
fi

#add Ultisnips snippets to .vim directory
make_link ~/.vim/UltiSnips ~/dotfiles/vim/UltiSnips/
