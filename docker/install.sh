#!/usr/bin/env bash

sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fssl https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
sudo apt install docker-ce
sudo usermod -aG docker ${USER}
