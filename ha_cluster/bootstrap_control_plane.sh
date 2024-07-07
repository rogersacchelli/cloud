#!/bin/bash

#System Package Managers Update
sudo apt-get update && sudo apt-get -y install aptitude


# Install packages

sudo aptitude -y install ansible dnsutils tree tcpdump zip unzip traceroute xml-twig-tools libgtk-3-0 libdbus-glib-1-2 libx11-xcb1 libxt6 kafkacat libxml2-dev libxslt1-dev libncurses-dev python3-pip openssh-server openjdk-17-jre jq

# Firewall
sudo ufw allow ssh
sudo ufw allow 433/tcp
sudo ufw allow 4335/tcp
sudo ufw allow 6514/tcp
sudo ufw allow 6515/tcp
sudo ufw allow 30101/tcp
sudo ufw allow 6443/tcp
sudo ufw allow 6443/tcp

# System routing
sudo sysctl -w net.ipv4.ip_forward=1
echo 'sysctl -w net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf

# Run the following command on server host where you are going to run IndexSearch.
sudo sysctl -w vm.max_map_count=262144
# The above command will modify the VM setting at run time. In order to persist this 
# setting even after reboot, add this setting to /etc/sysctl.conf file. 
sudo bash -c 'cat <<EOF >> /etc/sysctl.conf
vm.max_map_count=262144
EOF'
cat /proc/sys/net/ipv4/tcp_keepalive_time
cat /proc/sys/net/ipv4/tcp_keepalive_intvl
cat /proc/sys/net/ipv4/tcp_keepalive_probes

echo 1800 > /proc/sys/net/ipv4/tcp_keepalive_time

# To keep persistent:

sudo bash -c 'cat <<EOF >> /etc/sysctl.conf
net.ipv4.tcp_keepalive_time=1800
EOF'

sudo apt-get update
#sudo apt policy containerd
sudo apt-get install -y containerd

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce
sudo systemctl status docker

sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


# Install kubeadm

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.26/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.26/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubeadm kubelet kubernetes-cni kubectl

sudo apt-mark hold kubelet kubeadm kubectl

# Install Helm

## Install Helm

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

## Start Kubernetes

containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo kubeadm config images pull

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.0.2.15

sleep 10

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "export KUBECONFIG=$HOME/.kube/config" >>  $HOME/.bashrc
source $HOME/.bashrc

sleep 20

# Install Calico
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/calico.yaml -O
kubectl apply -f calico.yaml

# Install Flannel
#kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml


kubectl taint nodes --all node-role.kubernetes.io/control-plane-

sleep 20

sudo aptitude -y install bash-completion
echo "source <(kubectl completion bash)" >> $HOME/.bashrc

sudo usermod -aG docker $USER


sudo shutdown now -r
