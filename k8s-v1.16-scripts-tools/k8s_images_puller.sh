#!/bin/sh

images=(
    kube-apiserver-amd64:v1.11.2
    kube-controller-manager-amd64:v1.11.2
    kube-scheduler-amd64:v1.11.2
    kube-proxy-amd64:v1.11.2
    pause:3.1
    etcd-amd64:3.2.18
    coredns:1.1.3
)

for image in ${images[@]};do
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/${image}
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/${image} k8s.gcr.io/${image}
    docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/${image}
done

calico_images=(
    quay.io/calico/typha:v3.1.7
    quay.io/calico/node:v3.1.7
    quay.io/calico/cni:v3.1.7
)

for image in ${calico_images[@]};do
    docker pull ${image}
done

dashboard_images=(
    kubernetesui/dashboard:v2.0.0-beta4
    kubernetesui/metrics-scraper:v1.0.1
)

for image in ${dashboard_images[@]};do
    docker pull ${image}
done

