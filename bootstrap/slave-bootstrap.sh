#!/bin/bash
export JUPYTERHUB_HOST="${jademaster_private_ip}"
export IP_ADDR=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

# install deps
yum update -y
yum install -y git nfs-utils

echo "${jademaster_private_ip} jupyterhub" >> /etc/hosts

# mount network fileystems
service nfs start
mkdir -p /mnt/jade-notebooks
mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).fs-841df44d.efs.eu-west-1.amazonaws.com:/ /mnt/jade-notebooks

# install docker
yum install -y docker

# Make docker listen on tcp
sed -i '/^OPTIONS/ d' /etc/sysconfig/docker
echo "OPTIONS=\"--default-ulimit nofile=1024:4096 -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock\"" >> /etc/sysconfig/docker

# Start Docker
service docker start

# Install Docker Compose
curl -L https://github.com/docker/compose/releases/download/1.6.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
usermod -aG docker ec2-user

# get config
git clone https://github.com/met-office-lab/jade.git /usr/local/share/jade

# get keys
aws s3 cp s3://jade-secrets/jade-secrets /usr/local/share/jade/jade-secrets

# pull scientific environment image
docker pull quay.io/informaticslab/asn-serve

# run config
/usr/local/bin/docker-compose -f /usr/local/share/jade/docker/slave/docker-compose.yml up -d
