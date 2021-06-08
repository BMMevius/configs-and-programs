#!/usr/bin/env sh

# Install ZSH
sudo apt-get -y --no-install-recommends install zsh
sudo chsh -s "$(which zsh)"

# Install Oh-My-ZSH
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zdharma/history-search-multi-word.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/history-search-multi-word
git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting

# Install docker
sh -c "$(curl -fsSL https://get.docker.com)"

# Install OpenVPN
wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg|apt-key add -
echo "deb http://build.openvpn.net/debian/openvpn/stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/openvpn-aptrepo.list > /dev/null
sudo apt-get update
sudo apt-get install openvpn

# Install CUDA
sudo apt-get install linux-headers-"$(uname -r)"
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda-repo-ubuntu2004-11-3-local_11.3.1-465.19.01-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-3-local_11.3.1-465.19.01-1_amd64.deb
sudo apt-key add /var/cuda-repo-ubuntu2004-11-3-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda
# sudo apt-get install cuda-drivers-<input>

# Install Balena
curl -L https://github.com/balena-io/balena-cli/releases/download/v12.44.19/balena-cli-v12.44.19-linux-x64-standalone.zip -o balena.zip
sudo unzip -d /opt -o balena.zip
rm balena.zip

# Install AWS
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -d awscliv2 awscliv2.zip
sudo ./awscliv2/aws/install
rm -rf awscliv2 awscliv2.zip
