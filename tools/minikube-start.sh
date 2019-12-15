#!/bin/sh

minikube start \
    --image-mirror-country cn \
    --iso-url=https://kubernetes.oss-cn-hangzhou.aliyuncs.com/minikube/iso/minikube-v1.5.0.iso \
    --vm-driver=virtualbox \
    --registry-mirror=https://registry.docker-cn.com \
    --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
