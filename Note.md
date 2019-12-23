# k8s Note

## kube-scheduler

* kube-scheduler 配置
* 调度流程，预选和优选
* 预选算法
* 优选算法
* 调度策略的配置
* 调度器优化
* 自定义调度器

## kubelet

* kubelet 配置
* 自注册模式与非自注册模式
* 监听的 Pod 清单来源，api server、http 端点、本地文件
* 容器健康检查
    - 两类探针，LivenessProbe 和 ReadinessProbe
    - 探针的三种实现方式，ExecAction、TCPSocketAction、HTTPGetAction
* 资源监控，Heapster 提供集群级别的监控和事件聚合，cAdvisor 提供容器级别的监控

## kube-controller-manager

* kube-controller-manager 配置
* controllers
    * Replication Controller
        - 只有 Pod 的重启策略为 Always 时，Replication Controller 才会管理该 Pod 的操作
    * Node Controller
    * ResourceQuota Controller
        - 三个层次的资源配额管理，分别是容器级别、Pod 级别和 Namespace 级别
        - Admission Control 提供两种类型的配额约束，LimitRanger（用于 Pod 和 Container） 和 ResourceQuota（用于 Namespace ）
    * Namespace Controller
    * ServiceAccount Controller
    * Token Controller
    * Service Controller
    * Endpoint Controller

## kube-apiserver

* api 接口
* proxy api 接口

## kube-proxy

* 网络包的转发过程

## 共享存储

* PV、PVC、StorageClass


