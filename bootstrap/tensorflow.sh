#!/bin/bash
# Based on https://research.euranova.eu/installing-tensorflow-with-distributed-gpu-support/

# swapfile (avoid running out of RAM)
sudo dd if=/dev/zero of=swapfile bs=1M count=3000
sudo mkswap swapfile
sudo swapon swapfile

sudo apt-get update
sudo apt-get install -y pkg-config zip g++ zlib1g-dev unzip swig git

# java
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get install -y oracle-java8-installer

# bazel
cd /home/ubuntu && wget https://github.com/bazelbuild/bazel/releases/download/0.3.1/bazel_0.3.1-linux-x86_64.deb
cd /home/ubuntu && sudo su - ubuntu -c "sudo dpkg -i bazel_0.3.1-linux-x86_64.deb"

# build grpc server
cd /home/ubuntu && sudo git clone --recursive https://github.com/tensorflow/tensorflow
export PYTHON_BIN_PATH=/usr/bin/python
export TF_NEED_GCP=0
export TF_NEED_HDFS=0
sudo apt-get install python-pip -y

cd /home/ubuntu && sudo touch ./input && sudo chmod 777 ./input && sudo echo -en '\n\n\n\n\n' > ./input

sudo apt-get install -y python-dev python-numpy
cd /home/ubuntu/tensorflow && sudo bash ./configure < ../input

cd /home/ubuntu/tensorflow && sudo bazel build -c opt //tensorflow/core/distributed_runtime/rpc:grpc_tensorflow_server # no gpu
cd /home/ubuntu/tensorflow && sudo bazel build -c opt //tensorflow/tools/pip_package:build_pip_package # no gpu
cd /home/ubuntu/tensorflow && sudo bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
cd /home/ubuntu/tensorflow && sudo pip install /tmp/tensorflow_pkg/tensorflow-0.11.0rc0-cp27-none-linux_x86_64.whl

# run
# cd /home/ubuntu/tensorflow && sudo bazel-bin/tensorflow/core/distributed_runtime/rpc/grpc_tensorflow_server --cluster_spec='local|localhost:2222' --job_name=local --task_id=0 &
