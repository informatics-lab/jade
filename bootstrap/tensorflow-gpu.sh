#!/bin/bash
# Based on https://alliseesolutions.wordpress.com/2016/09/08/install-gpu-tensorflow-from-sources-w-ubuntu-16-04-and-cuda-8-0-rc/

# swapfile (avoid running out of RAM)
sudo dd if=/dev/zero of=swapfile bs=1M count=3000
sudo mkswap swapfile
sudo swapon swapfile

sudo apt-get update
sudo apt-get install -y pkg-config zip g++ zlib1g-dev unzip swig git
sudo apt-get install -y git python-dev python3-dev python-numpy python3-numpy build-essential python-pip python3-pip python-virtualenv swig python-wheel libcurl3-dev

# install drivers
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt-get update
sudo apt-get install -y ubuntu-drivers-common

# java
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get install -y oracle-java8-installer

# bazel
cd /home/ubuntu && wget https://github.com/bazelbuild/bazel/releases/download/0.3.2/bazel_0.3.2-linux-x86_64.deb
cd /home/ubuntu && sudo su - ubuntu -c "sudo dpkg -i bazel_0.3.2-linux-x86_64.deb"

# cuda
wget https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda_8.0.44_linux-run
chmod 775 cuda_8.0.44_linux-run
sudo apt-get install linux-headers-$(uname -r)
sudo apt-get install -y dkms
sudo echo -en "blacklist nouveau \n options nouveau modeset=0" > /etc/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u
sh ./cuda_8.0.44_linux-run --silent --driver --toolkit --toolkitpath=/mnt/cuda-8.0 --no-opengl-libs

wget https://s3-eu-west-1.amazonaws.com/asn-cuda/cudnn-8.0-linux-x64-v5.1.tgz
tar -xf cudnn-8.0-linux-x64-v5.1.tgz
sudo cp cuda/include/cudnn.h /usr/local/cuda/include/
sudo cp --preserve=links cuda/lib64/libcudnn* /usr/local/cuda/lib64/
sudo chmod a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn*

# build tensorflow grpc server
cd /home/ubuntu && sudo git clone --recursive https://github.com/tensorflow/tensorflow
cd /home/ubuntu && git checkout tags/v0.11.0rc1 -b v0.11.0rc1
export PYTHON_BIN_PATH=/usr/bin/python
export TF_NEED_GCP=0
export TF_NEED_HDFS=0
export TF_NEED_CUDA=1
export TF_CUDA_COMPUTE_CAPABILITIES=3.0

cd /home/ubuntu && sudo touch ./input && sudo chmod 777 ./input && sudo echo -en '\n\n\n\n\n\n\n' > ./input
cd /home/ubuntu/tensorflow && sudo -E bash ./configure < ../input

cd /home/ubuntu/tensorflow && sudo bazel build -c opt --config=cuda //tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server
# cd /home/ubuntu/tensorflow && sudo bazel build -c opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
# cd /home/ubuntu/tensorflow && sudo bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
# cd /home/ubuntu/tensorflow && sudo pip install /tmp/tensorflow_pkg/tensorflow-0.11.0rc1-cp27-none-linux_x86_64.whl

# config to serve
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
export CUDA_HOME=/usr/local/cuda
sudo ldconfig /usr/local/cuda/lib64
sudo su - ubuntu -c "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
sudo su - ubuntu -c "export CUDA_HOME=/usr/local/cuda"
sudo su - ubuntu -c "sudo ldconfig /usr/local/cuda/lib64"

cd /home/ubuntu && touch ./donefile