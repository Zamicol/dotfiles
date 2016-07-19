#!/bin/sh
# When possible, use XDG directory structure.
#To change look and feel, use lxappearance


###############
###############
# Start
###############
###############
# If using bash
# -e Exit if errors
# -u Exit if variable is unset
#set -eu
# Dotfiles directory
DOTFILES="$HOME/.dotfiles"
# Set absolute path.  This is especially helpful for 'ln -s'.
DOTFILES=`cd "$DOTFILES"; pwd`

####################
# Repos
####################
# lxd-stable has golang packages.
REPOS="ppa:ubuntu-lxc/lxd-stable ppa:webupd8team/atom"

####################
# Packages
####################
# Packages to be installed on the system.
# Some of these are needed for this script,
PACKAGES="git vim curl openssh-server lynx htop tmux ncdu"

# Bloat packages
PACKAGES="$PACKAGES chromium-browser gparted emacs24 xclip"

# i3
# feh is for x desktop background.
# sysstat is for i3blocks cpu stats.
PACKAGES="$PACKAGES i3 dmenu i3status i3lock feh sysstat"

# MATE
# caja-share is for smb gui sharing.
PACKAGES="$PACKAGES caja-share"

# Dev packages
PACKAGES="$PACKAGES golang atom"

# QuickTile packages
PACKAGES="$PACKAGES python python-gtk2 python-xlib python-dbus python-wnck"

####################
# Files
####################
# Symlink from dotfiles to home.
# Will not overwrite existing
# Files with be prepended with a dot.
SYMLINKS="bashrc xsession profile xinitrc gitconfig fonts"
# Create these dirs if they do not yet exist.
DIRS="$HOME/dev/go $HOME/.config/i3 $HOME/.ssh $HOME/.config/i3status \
$HOME/.config/i3blocks $DOTFILES/fonts"


####################
####################
# Install
####################
####################

####################
# Make sure .bashrc is being used by the current shell environment
####################
#use "source" in bash
. $HOME/.bashrc
. $HOME/.profile

####################
# mkdirs
####################
for dir in $DIRS; do
  mkdir -p $dir
done

################
# Symlinks
################
for link in $SYMLINKS; do
  if [ ! -f $HOME/.$link ] && [ ! -d $HOME/.$link ]; then
    if ln -s $DOTFILES/$link $HOME/.$link ; then
      echo "Created link $HOME/.$link from $DOTFILES"
    fi
  else
      echo ".$link exists.  Not creating symbolic link."
  fi
done


####################
# Repos
####################
for r in $REPOS; do
  echo "Adding repo $r"
  sudo add-apt-repository $r -y
done
# Update packages that are now available
#sudo apt-get update


####################
# Install Packages
####################
echo "Installing packages $PACKAGES"
case $(uname -s) in
  OpenBSD)
  pkg_add $PACKAGES
  ;;
  Linux)
  if [ -e /etc/redhat-release ]; then
    sudo yum install $PACKAGES
  else
    sudo apt-get -y --ignore-missing install $PACKAGES
  fi
  ;;
  *)
  echo 'system unknown.  Not installing packages'
  ;;
esac


####################
# i3
####################
# Remove default config and link to dotfile config
rm $HOME/.i3/config
ln -s $DOTFILES/i3/config $HOME/.config/i3/config

# i3status and i3block
# this config should read first before the "default" /etc/i3status.conf
# accodring to https://i3wm.org/i3status/manpage.html and
# https://vivien.github.io/i3blocks/
ln -s $DOTFILES/i3/i3status.conf $HOME/.config/i3status/config
ln -s $DOTFILES/i3/i3blocks.conf $HOME/.config/i3blocks/config
# i3blocks
git clone git://github.com/vivien/i3blocks $HOME/dev/i3blocks
(cd $HOME/dev/i3blocks/ && make clean debug && sudo make install)


####################
# ssh
####################
echo "Setting up ssh"
if [ ! -d $HOME/.ssh ]; then
  chmod 700 $HOME/.ssh
  ssh-keygen -t rsa -N "" -f $HOME/.ssh/id_rsa
fi
if [ ! -f $HOME/.ssh/authorized_keys ]; then
  cp $DOTFILES/authorized_keys $HOME/.ssh/authorized_keys
fi


###############
# Quicktile
###############
if [ ! -f $HOME/.config/quicktile.cfg ]; then
  echo "Installing Quicktile"
  git clone https://github.com/ssokolow/quicktile.git
  cd quicktile
  sudo ./setup.py install
  cd ..
else
  echo "$HOME/.config/quicktile.cfg exists.  Not installing quicktile"
fi


####################
# Fonts
####################
# -N update only on new, -P specify directory, and -q is quiet
wget -Nq -P $HOME/.fonts/ \
https://github.com/supermarin/YosemiteSanFranciscoFont/raw/master/System%20San%20Francisco%20Display%20Bold.ttf  \
https://github.com/supermarin/YosemiteSanFranciscoFont/raw/master/System%20San%20Francisco%20Display%20Regular.ttf \
https://github.com/supermarin/YosemiteSanFranciscoFont/raw/master/System%20San%20Francisco%20Display%20Thin.ttf \
https://github.com/supermarin/YosemiteSanFranciscoFont/raw/master/System%20San%20Francisco%20Display%20Ultralight.ttf \
https://github.com/FortAwesome/Font-Awesome/raw/master/fonts/fontawesome-webfont.ttf


####################
# vim
####################
# vim's settings are stored in the home directory
if [ ! -d "$HOME/.vim" ]; then
  echo 'Cloning vim'
  git clone git://github.com/Zamicol/dotvim.git $HOME/.vim
  if (( $? != 0 )); then
    # Port blocked?  Try https
    echo 'attempting clone via https'
    git clone https://github.com/Zamicol/dotvim.git $HOME/.vim
  fi

  if (( $? == 0 )); then
    echo 'cloned vim to $HOME/.vim'
    cd $HOME/.vim
    git submodule init
    git submodule update
    # create symbolic link in home so vim can see the settings
    if [ ! -f $HOME/.vimrc ]; then
      ln -s $HOME/.vim/vimrc $HOME/.vimrc
    else
      echo '.vimrc exists.  Not creating symbolic link'
    fi
  else
    echo 'unable to clone vim'
  fi
fi


####################
# emacs
####################
if [ ! -d "$HOME/.emacs.d" ]; then
  # prelude
  # All settings should be stored in the personal directory
  # so it is easy to merge from the main project.
  # git clone https://github.com/Zamicol/prelude.git prelude
  # ln -s  	$HOME/$DOTFILES/prelude $HOME/.emacs.d
  # echo 'installed emacs prelude'i

  # zami's plain jane emacs repo.
  # emacs should initialize everything else on first run.
  git clone https://github.com/Zamicol/emacs.git $HOME/.emacs.d
  echo 'cloned emacs to $HOME/.emacs.d'
else
  echo '.emacs.d exists.  Not cloning emacs'
fi


####################
# xmodmap
####################
# also in xsession and xinitrc, putting it here to make sure that it runs
xmodmap $DOTFILES/xmodmap


####################
# Google Chrome
####################
if ! dpkg -l google-chrome-stable > /dev/null; then
  echo "Installing Google Chrome"
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
  sudo apt-get update
  sudo apt-get install google-chrome-stable
fi


####################
# golang
####################
# Golang gets installed via repo
# Golang's src on Debian is located at /usr/lib/go/src
echo "Golang"
# $GOPATH should be set in .profile
echo "gopath: $GOPATH"
echo "goroot: $GOROOT"
# Install go-plus in Atom section.  "apm" depends on atom.


####################
# Atom
####################
apm install go-plus
apm install minimap
