#!/bin/sh

images=(  # 下面的镜像应该去除"k8s.gcr.io/"的前缀，版本换成上面获取到的版本
	kube-apiserver:v1.16.0
	kube-controller-manager:v1.16.0
	kube-scheduler:v1.16.0
	kube-proxy:v1.16.0
	pause:3.1
	etcd:3.3.15-0
	coredns:1.6.2

)

for imageName in ${images[@]} ; do
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName k8s.gcr.io/$imageName
    docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
done
