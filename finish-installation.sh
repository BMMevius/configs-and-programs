#!/usr/bin/env bash

# Install ZSH plugins
git clone git@github.com:zdharma-continuum/history-search-multi-word.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/history-search-multi-word
git clone git@github.com:zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
git clone git@github.com:zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting

# Install fonts
font_dir=/usr/local/share/fonts
sudo -S mkdir -p "$font_dir"

# Install satoshi font
curl -fsSLO https://api.fontshare.com/v2/fonts/download/satoshi
unzip satoshi -d satoshi_fonts
mv satoshi_fonts/* "$font_dir"
rm -rf satoshi_fonts satoshi

# Install mulish font
git clone git@github.com:googlefonts/mulish.git
mkdir -p "$font_dir/mulish"
cp mulish/fonts/ttf "$font_dir/mulish"
rm -rf mulish

# Update font cache
fc-cache
