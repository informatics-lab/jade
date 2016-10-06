#!/bin/bash
# Following https://github.com/fluxcapacitor/pipeline/wiki/AWS-GPU-TensorFlow-Docker

# Setup Nvidia Drivers
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt-get update
sudo apt-get install -y dkms 
sudo apt-get install -y linux-headers-generic
sudo apt-get install -y nvidia-361
echo blacklist nouveau | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u
sudo apt-get install -y nvidia-modprobe

# get docker
sudo apt-get update
sudo curl -fsSL https://get.docker.com/ | sh
sudo curl -fsSL https://get.docker.com/gpg | sudo apt-key add -

# setup nvidia docker
wget https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.0-rc.3/nvidia-docker_1.0.0.rc.3-1_amd64.deb
sudo dpkg -i nvidia-docker_1.0.0.rc.3-1_amd64.deb
sudo rm nvidia-docker_1.0.0.rc.3-1_amd64.deb

# tensorflow
sudo docker pull gcr.io/tensorflow/tensorflow:0.10.0-gpu
sudo nvidia-docker run -itd --name=tensorflow-gpu -p 8754:8888 -p 6006:6006 -p 2222:2222 -p 2223:2223 gcr.io/tensorflow/tensorflow:0.10.0-gpu

