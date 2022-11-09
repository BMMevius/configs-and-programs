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
sudo cp blobfuse2 /usr/bin

# Clean up
cd ~
rm -rf azure-storage-fuse
yay -R go

# Mount azure blob filesystem
mount_path=/run/media/$USER/azure
config_file_path=~/azure-config.yml
sudo mkdir "$mount_path"
sudo chown "$USER" "$mount_path"
if [ -z "$(blobfuse2 mount all "$mount_path" --config-file=$config_file_path > /dev/null 2>&1)" ]; then
    echo "The config file located at $config_file_path probably did not have a key yet.

Put the key in the azure config and execute the following command:
$ blobfuse2 mount all $mount_path --config-file=$config_file_path
    
You can get this key at:
https://portal.azure.com/#@sorama.eu/resource/subscriptions/e6307c1b-ee67-4f60-a476-dc9502946fed/resourceGroups/AzureBackupRG_westeurope_1/providers/Microsoft.Storage/storageAccounts/soramasharedstorage/keys"
fi