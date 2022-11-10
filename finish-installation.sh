#!/usr/bin/env bash

set -e

# Install ZSH plugins
git clone git@github.com:zdharma-continuum/history-search-multi-word.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/history-search-multi-word
git clone git@github.com:zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
git clone git@github.com:zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting

# Install blobfuse2
# https://learn.microsoft.com/en-us/azure/storage/blobs/blobfuse2-how-to-deploy#install-blobfuse2
cd ~
git clone https://github.com/Azure/azure-storage-fuse/
cd ./azure-storage-fuse
git checkout main

# Build
yay -Sy go
go get
./build
sudo mv blobfuse2 /usr/local/bin/blobfuse2

# Clean up
cd ~
rm -rf azure-storage-fuse
yay -R go

# Mount azure blob filesystem
mount_path=/run/media/azure
sudo mkdir "$mount_path"
sudo systemctl start blobfuse2
