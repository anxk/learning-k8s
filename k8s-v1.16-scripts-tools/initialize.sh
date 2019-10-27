#!/bin/sh

set -ex

# Set kubernetes.repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

# Set SELinux in permissive mode
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Set iptables config
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Set swappiness
swapoff -a
cat <<EOF >> /etc/sysctl.d/k8s.conf
vm.swappiness=0
EOF

# Reload sysctl config
sysctl --system

# Install kubelet kubeadm kubectl
yum install -y kubelet-1.11.2-0 kubectl-1.11.2-0 kubeadm-1.11.2-0 --disableexcludes=kubernetes

# restart kubelet
systemctl daemon-reload
systemctl restart kubelet
systemctl enable kubelet
