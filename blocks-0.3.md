[TOC]

# k8s v0.3 blocks

### github.com/GoogleCloudPlatform/kubernetes/pkg/kubelet/capabilities

```go
// package capbabilities manages system level capabilities
package capabilities
```
```go
// Capabilities defines the set of capabilities available within the system.
// For now these are global.  Eventually they may be per-user
type Capabilities struct {
    AllowPrivileged bool
}

var once sync.Once
var capabilities *Capabilities
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/constraint

```go
// Package constraint has functions for ensuring that collections of
// containers are allowed to run together on a single host.
//
// TODO: Add resource math. Phrase this code in a way that makes it easy
// to call from schedulers as well as from the feasiblity check that
// apiserver performs.
package constraint
```
```go
// Allowed returns true if manifests is a collection of manifests
// which can run without conflict on a single minion.
func Allowed(manifests []api.ContainerManifest) bool {
    return !PortsConflict(manifests)
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/controller

```go
// Package controller contains logic for watching and synchronizing
// replicationControllers.
package controller
```
```go
// ReplicationManager is responsible for synchronizing ReplicationController objects stored
// in the system with actual running pods.
type ReplicationManager struct {
    kubeClient client.Interface
    podControl PodControlInterface
    syncTime   <-chan time.Time

    // To allow injection of syncReplicationController for testing.
    syncHandler func(controllerSpec api.ReplicationController) error
}
```
```go
// PodControlInterface is an interface that knows how to add or delete pods
// created as an interface to allow testing.
type PodControlInterface interface {
    // createReplica creates new replicated pods according to the spec.
    createReplica(controllerSpec api.ReplicationController)
    // deletePod deletes the pod identified by podID.
    deletePod(podID string) error
}
```
```go
// RealPodControl is the default implementation of PodControllerInterface.
type RealPodControl struct {
    kubeClient client.Interface
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/election

```go
// Package election provides interfaces used for master election.
package election
```
```go
// MasterElector is an interface for services that can elect masters.
// Important Note: MasterElectors are not inter-operable, all participants in the election need to be
//  using the same underlying implementation of this interface for correct behavior.
type MasterElector interface {
    // RequestMaster makes the caller represented by 'id' enter into a master election for the
    // distributed lock defined by 'path'
    // The returned watch.Interface provides a stream of Master objects which
    // contain the current master.
    // Calling Stop on the returned interface relinquishes ownership (if currently possesed)
    // and removes the caller from the election
    Elect(path, id string) watch.Interface
}
```
```go
// Master is used to announce the current elected master.
type Master string
```
```go
type empty struct{}
```
```go
// internal implementation struct
type etcdMasterElector struct {
    etcd   tools.EtcdGetSet
    done   chan empty
    events chan watch.Event
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/health

```go
// Package health contains utilities for health checking, as well as health status information.
package health
```
```go
// Status represents the result of a single health-check operation.
type Status int
```
```go
// Status values must be one of these constants.
const (
    Healthy Status = iota
    Unhealthy
    Unknown
)
```
```go
// HealthChecker defines an abstract interface for checking container health.
type HealthChecker interface {
    HealthCheck(podFullName string, currentState api.PodState, container api.Container) (Status, error)
}
```
```go
// protects checkers
var checkerLock = sync.Mutex{}
var checkers = map[string]HealthChecker{}
```
```go
// muxHealthChecker bundles multiple implementations of HealthChecker of different types.
type muxHealthChecker struct {
    checkers map[string]HealthChecker
}
```
```go
const defaultHealthyRegex = "^OK$"
```
```go
type CommandRunner interface {
    RunInContainer(podFullName, uuid, containerName string, cmd []string) ([]byte, error)
}
```
```go
type ExecHealthChecker struct {
    runner CommandRunner
}
```
```go
// HTTPGetInterface is an abstract interface for testability. It abstracts the interface of http.Client.Get.
// This is exported because some other packages may want to do direct HTTP checks.
type HTTPGetInterface interface {
    Get(url string) (*http.Response, error)
}
```
```go
// HTTPHealthChecker is an implementation of HealthChecker which checks container health by sending HTTP Get requests.
type HTTPHealthChecker struct {
    client HTTPGetInterface
}
```
```go
type TCPHealthChecker struct{}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/healthz

```go
// Package healthz implements basic http server health checking.
// Usage:
//   import _ "healthz" registers a handler on the path '/healthz', that serves 200s
package healthz
```
```go
// mux is an interface describing the methods InstallHandler requires.
type mux interface {
    HandleFunc(pattern string, handler func(http.ResponseWriter, *http.Request))
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/kubelet

```go
// Package kubelet is the package that contains the libraries that drive the Kubelet binary.
// The kubelet is responsible for node level pod management.  It runs on each worker in the cluster.
package kubelet
```
```go
type execActionHandler struct {
    kubelet *Kubelet
}
```
```go
type httpActionHandler struct {
    kubelet *Kubelet
    client  httpGetInterface
}
```
```go
const defaultChanSize = 1024

// taken from lmctfy https://github.com/google/lmctfy/blob/master/lmctfy/controllers/cpu_controller.cc
const minShares = 2
const sharesPerCPU = 1024
const milliCPUToCPU = 1000

// CadvisorInterface is an abstract interface for testability.  It abstracts the interface of "github.com/google/cadvisor/client".Client.
type CadvisorInterface interface {
    ContainerInfo(name string, req *info.ContainerInfoRequest) (*info.ContainerInfo, error)
    MachineInfo() (*info.MachineInfo, error)
}

// SyncHandler is an interface implemented by Kubelet, for testability
type SyncHandler interface {
    SyncPods([]Pod) error
}

type volumeMap map[string]volume.Interface
```
```go
type httpGetInterface interface {
    Get(url string) (*http.Response, error)
}
```
```go
// Kubelet is the main kubelet implementation.
type Kubelet struct {
    hostname       string
    dockerClient   dockertools.DockerInterface
    rootDirectory  string
    podWorkers     podWorkers
    resyncInterval time.Duration

    // Optional, no events will be sent without it
    etcdClient tools.EtcdClient
    // Optional, no statistics will be available if omitted
    cadvisorClient CadvisorInterface
    // Optional, defaults to simple implementaiton
    healthChecker health.HealthChecker
    // Optional, defaults to simple Docker implementation
    dockerPuller dockertools.DockerPuller
    // Optional, defaults to /logs/ from /var/log
    logServer http.Handler
    // Optional, defaults to simple Docker implementation
    runner dockertools.ContainerCommandRunner
    // Optional, client for http requests, defaults to empty client
    httpClient httpGetInterface
}
```
```go
// Per-pod workers.
type podWorkers struct {
    lock sync.Mutex

    // Set of pods with existing workers.
    workers util.StringSet
}
```
```go
// A basic interface that knows how to execute handlers
type actionHandler interface {
    Run(podFullName, uuid string, container *api.Container, handler *api.Handler) error
}
```
```go
const (
    networkContainerName  = "net"
    networkContainerImage = "kubernetes/pause:latest"
)
```
```go
type empty struct{}
```
```go
type podContainer struct {
    podFullName   string
    uuid          string
    containerName string
}
```
```go
// Server is a http.Handler which exposes kubelet functionality over HTTP.
type Server struct {
    host    HostInterface
    updates chan<- interface{}
    mux     *http.ServeMux
}
```
```go
// HostInterface contains all the kubelet methods required by the server.
// For testablitiy.
type HostInterface interface {
    GetContainerInfo(podFullName, uuid, containerName string, req *info.ContainerInfoRequest) (*info.ContainerInfo, error)
    GetRootInfo(req *info.ContainerInfoRequest) (*info.ContainerInfo, error)
    GetMachineInfo() (*info.MachineInfo, error)
    GetPodInfo(name, uuid string) (api.PodInfo, error)
    RunInContainer(name, uuid, container string, cmd []string) ([]byte, error)
    ServeLogs(w http.ResponseWriter, req *http.Request)
}
```
```go
// Pod represents the structure of a pod on the Kubelet, distinct from the apiserver
// representation of a Pod.
type Pod struct {
    Namespace string
    Name      string
    Manifest  api.ContainerManifest
}

// PodOperation defines what changes will be made on a pod configuration.
type PodOperation int

const (
    // This is the current pod configuration
    SET PodOperation = iota
    // Pods with the given ids are new to this source
    ADD
    // Pods with the given ids have been removed from this source
    REMOVE
    // Pods with the given ids have been updated in this source
    UPDATE
)

// PodUpdate defines an operation sent on the channel. You can add or remove single services by
// sending an array of size one and Op == ADD|REMOVE (with REMOVE, only the ID is required).
// For setting the state of the system to a given state for this source configuration, set
// Pods as desired and Op to SET, which will reset the system state to that specified in this
// operation for this source channel. To remove all pods, set Pods to empty array and Op to SET.
type PodUpdate struct {
    Pods []Pod
    Op   PodOperation
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/kubelet/config

```go
// Package config implements the pod configuration readers.
package config
```
```go
// PodConfigNotificationMode describes how changes are sent to the update channel.
type PodConfigNotificationMode int

const (
    // PodConfigNotificationSnapshot delivers the full configuration as a SET whenever
    // any change occurs.
    PodConfigNotificationSnapshot = iota
    // PodConfigNotificationSnapshotAndUpdates delivers an UPDATE message whenever pods are
    // changed, and a SET message if there are any additions or removals.
    PodConfigNotificationSnapshotAndUpdates
    // PodConfigNotificationIncremental delivers ADD, UPDATE, and REMOVE to the update channel.
    PodConfigNotificationIncremental
)

// PodConfig is a configuration mux that merges many sources of pod configuration into a single
// consistent structure, and then delivers incremental change notifications to listeners
// in order.
type PodConfig struct {
    pods *podStorage
    mux  *config.Mux

    // the channel of denormalized changes passed to listeners
    updates chan kubelet.PodUpdate
}
```
```go
// podStorage manages the current pod state at any point in time and ensures updates
// to the channel are delivered in order.  Note that this object is an in-memory source of
// "truth" and on creation contains zero entries.  Once all previously read sources are
// available, then this object should be considered authoritative.
type podStorage struct {
    podLock sync.RWMutex
    // map of source name to pod name to pod reference
    pods map[string]map[string]*kubelet.Pod
    mode PodConfigNotificationMode

    // ensures that updates are delivered in strict order
    // on the updates channel
    updateLock sync.Mutex
    updates    chan<- kubelet.PodUpdate
}
```
```go
type SourceEtcd struct {
    key     string
    helper  tools.EtcdHelper
    updates chan<- interface{}
}
```
```go
type SourceFile struct {
    path    string
    updates chan<- interface{}
}
```
```go
var simpleSubdomainSafeEncoding = base32.NewEncoding("0123456789abcdefghijklmnopqrstuv")
var unsafeDNSLabelReplacement = regexp.MustCompile("[^a-z0-9]+")
```
```go
type SourceURL struct {
    url     string
    updates chan<- interface{}
    data    []byte
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/kubelet/dockertools

```go
const (
    dockerConfigFileLocation = ".dockercfg"
)
```
```go
// dockerConfig represents the config file used by the docker CLI.
// This config that represents the credentials that should be used
// when pulling images from specific image repositories.
type dockerConfig map[string]dockerConfigEntry
```
```go
type dockerConfigEntry struct {
    Username string
    Password string
    Email    string
}
```
```go
// dockerConfigEntryWithAuth is used solely for deserializing the Auth field
// into a dockerConfigEntry during JSON deserialization.
type dockerConfigEntryWithAuth struct {
    Username string
    Password string
    Email    string
    Auth     string
}
```
```go
// DockerContainerData is the structured representation of the JSON object returned by Docker inspect
type DockerContainerData struct {
    state struct {
        Running bool
    }
}

// DockerInterface is an abstract interface for testability.  It abstracts the interface of docker.Client.
type DockerInterface interface {
    ListContainers(options docker.ListContainersOptions) ([]docker.APIContainers, error)
    InspectContainer(id string) (*docker.Container, error)
    CreateContainer(docker.CreateContainerOptions) (*docker.Container, error)
    StartContainer(id string, hostConfig *docker.HostConfig) error
    StopContainer(id string, timeout uint) error
    PullImage(opts docker.PullImageOptions, auth docker.AuthConfiguration) error
}

// DockerID is an ID of docker container. It is a type to make it clear when we're working with docker container Ids
type DockerID string

// DockerPuller is an abstract interface for testability.  It abstracts image pull operations.
type DockerPuller interface {
    Pull(image string) error
}

// dockerPuller is the default implementation of DockerPuller.
type dockerPuller struct {
    client  DockerInterface
    keyring *dockerKeyring
}
```
```go
type dockerContainerCommandRunner struct{}
```
```go
// DockerContainers is a map of containers
type DockerContainers map[DockerID]*docker.APIContainers
```
```go
// ErrNoContainersInPod is returned when there are no containers for a given pod
var ErrNoContainersInPod = errors.New("no containers exist for this pod")
```
```go
const containerNamePrefix = "k8s"
```
```go
type ContainerCommandRunner interface {
    RunInContainer(containerID string, cmd []string) ([]byte, error)
}
```
```go
// dockerKeyring tracks a set of docker registry credentials, maintaining a
// reverse index across the registry endpoints. A registry endpoint is made
// up of a host (e.g. registry.example.com), but it may also contain a path
// (e.g. registry.example.com/foo) This index is important for two reasons:
// - registry endpoints may overlap, and when this happens we must find the
//   most specific match for a given image
// - iterating a map does not yield predictable results
type dockerKeyring struct {
    index []string
    creds map[string]docker.AuthConfiguration
}
```
```go
// FakeDockerClient is a simple fake docker client, so that kubelet can be run for testing without requiring a real docker setup.
type FakeDockerClient struct {
    sync.Mutex
    ContainerList []docker.APIContainers
    Container     *docker.Container
    Err           error
    called        []string
    Stopped       []string
    pulled        []string
    Created       []string
}
```
```go
// FakeDockerPuller is a stub implementation of DockerPuller.
type FakeDockerPuller struct {
    sync.Mutex

    ImagesPulled []string

    // Every pull will return the first error here, and then reslice
    // to remove it. Will give nil errors if this slice is empty.
    ErrorsToInject []error
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/labels

```go
// Package labels implements a simple label system, parsing and matching
// selectors with sets of labels.
package labels
```
```go
// Labels allows you to present labels independently from their storage.
type Labels interface {
    // Get returns the value for the provided label.
    Get(label string) (value string)
}
```
```go
// Set is a map of label:value. It implements Labels.
type Set map[string]string
```
```go
// Selector represents a label selector.
type Selector interface {
    // Matches returns true if this selector matches the given set of labels.
    Matches(Labels) bool

    // Empty returns true if this selector does not restrict the selection space.
    Empty() bool

    // RequiresExactMatch allows a caller to introspect whether a given selector
    // requires a single specific label to be set, and if so returns the value it
    // requires.
    // TODO: expand this to be more general
    RequiresExactMatch(label string) (value string, found bool)

    // String returns a human readable string that represents this selector.
    String() string
}
```
```go
type hasTerm struct {
    label, value string
}
```
```go
type notHasTerm struct {
    label, value string
}
```
```go
type andTerm []Selector
```
```go
// Operator represents a key's relationship
// to a set of values in a Requirement.
// TODO: Should also represent key's existence.
type Operator int

const (
    IN Operator = iota + 1
    NOT_IN
)

// LabelSelector only not named 'Selector' due
// to name conflict until Selector is deprecated.
type LabelSelector struct {
    Requirements []Requirement
}

type Requirement struct {
    key       string
    operator  Operator
    strValues util.StringSet
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/master

```go
// Package master contains code for setting up and running a Kubernetes
// cluster master.
package master
```
```go
// Config is a structure used to configure a Master.
type Config struct {
    Client             *client.Client
    Cloud              cloudprovider.Interface
    EtcdHelper         tools.EtcdHelper
    HealthCheckMinions bool
    Minions            []string
    MinionCacheTTL     time.Duration
    MinionRegexp       string
    PodInfoGetter      client.PodInfoGetter
}

// Master contains state for a Kubernetes cluster master/api server.
type Master struct {
    podRegistry        pod.Registry
    controllerRegistry controller.Registry
    serviceRegistry    service.Registry
    endpointRegistry   endpoint.Registry
    minionRegistry     minion.Registry
    bindingRegistry    binding.Registry
    storage            map[string]apiserver.RESTStorage
    client             *client.Client
}
```
```go
// PodCache contains both a cache of container information, as well as the mechanism for keeping
// that cache up to date.
type PodCache struct {
    containerInfo client.PodInfoGetter
    pods          pod.Registry
    // This is a map of pod id to a map of container name to the
    podInfo map[string]api.PodInfo
    podLock sync.Mutex
}
```
```go
const (
    // KubeletPort is the default port for the kubelet status server on each host machine.
    // May be overridden by a flag at startup.
    KubeletPort = 10250
    // SchedulerPort is the default port for the scheduler status server.
    // May be overridden by a flag at startup.
    SchedulerPort = 10251
    // ControllerManagerPort is the default port for the controller manager status server.
    // May be overridden by a flag at startup.
    ControllerManagerPort = 10252
)
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/proxy

```go
// Package proxy implements the layer-3 network proxy.
package proxy
```
```go
type serviceInfo struct {
    port     int
    protocol string
    socket   proxySocket
    timeout  time.Duration
    mu       sync.Mutex // protects active
    active   bool
}
```
```go
// How long we wait for a connection to a backend.
const endpointDialTimeout = 5 ### time.Second

// Abstraction over TCP/UDP sockets which are proxied.
type proxySocket interface {
    // Addr gets the net.Addr for a proxySocket.
    Addr() net.Addr
    // Close stops the proxySocket from accepting incoming connections.  Each implementation should comment
    // on the impact of calling Close while sessions are active.
    Close() error
    // ProxyLoop proxies incoming connections for the specified service to the service endpoints.
    ProxyLoop(service string, proxier *Proxier)
}

// tcpProxySocket implements proxySocket.  Close() is implemented by net.Listener.  When Close() is called,
// no new connections are allowed but existing connections are left untouched.
type tcpProxySocket struct {
    net.Listener
}
```
```go
// udpProxySocket implements proxySocket.  Close() is implemented by net.UDPConn.  When Close() is called,
// no new connections are allowed and existing connections are broken.
// TODO: We could lame-duck this ourselves, if it becomes important.
type udpProxySocket struct {
    *net.UDPConn
}
```
```go
// Holds all the known UDP clients that have not timed out.
type clientCache struct {
    mu      sync.Mutex
    clients map[string]net.Conn // addr string -> connection
}
```
```go
// Proxier is a simple proxy for TCP connections between a localhost:lport
// and services that provide the actual implementations.
type Proxier struct {
    loadBalancer LoadBalancer
    mu           sync.Mutex // protects serviceMap
    serviceMap   map[string]*serviceInfo
    address      string
}
```
```go
// used to globally lock around unused ports. Only used in testing.
var unusedPortLock sync.Mutex
```
```go
// How long we leave idle UDP connections open.
const udpIdleTimeout = 1 ### time.Minute
```
```go
// LoadBalancer is an interface for distributing incoming requests to service endpoints.
type LoadBalancer interface {
    // NextEndpoint returns the endpoint to handle a request for the given
    // service and source address.
    NextEndpoint(service string, srcAddr net.Addr) (string, error)
}
```
```go
var (
    ErrMissingServiceEntry = errors.New("missing service entry")
    ErrMissingEndpoints    = errors.New("missing endpoints")
)

// LoadBalancerRR is a round-robin load balancer.
type LoadBalancerRR struct {
    lock         sync.RWMutex
    endpointsMap map[string][]string
    rrIndex      map[string]int
}
```
```go
// udpEchoServer is a simple echo server in UDP, intended for testing the proxy.
type udpEchoServer struct {
    net.PacketConn
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/proxy/config

```go
// Package config provides decoupling between various configuration sources (etcd, files,...) and
// the pieces that actually care about them (loadbalancer, proxy). Config takes 1 or more
// configuration sources and allows for incremental (add/remove) and full replace (set)
// changes from each of the sources, then creates a union of the configuration and provides
// a unified view for both service handlers as well as endpoint handlers. There is no attempt
// to resolve conflicts of any sort. Basic idea is that each configuration source gets a channel
// from the Config service and pushes updates to it via that channel. Config then keeps track of
// incremental & replace changes and distributes them to listeners as appropriate.
package config
```
```go
// Watcher is the interface needed to receive changes to services and endpoints.
type Watcher interface {
    ListServices(label labels.Selector) (*api.ServiceList, error)
    ListEndpoints(label labels.Selector) (*api.EndpointsList, error)
    WatchServices(label, field labels.Selector, resourceVersion uint64) (watch.Interface, error)
    WatchEndpoints(label, field labels.Selector, resourceVersion uint64) (watch.Interface, error)
}

// SourceAPI implements a configuration source for services and endpoints that
// uses the client watch API to efficiently detect changes.
type SourceAPI struct {
    client    Watcher
    services  chan<- ServiceUpdate
    endpoints chan<- EndpointsUpdate

    waitDuration      time.Duration
    reconnectDuration time.Duration
}
```
```go
// Operation is a type of operation of services or endpoints.
type Operation int

// These are the available operation types.
const (
    SET Operation = iota
    ADD
    REMOVE
)

// ServiceUpdate describes an operation of services, sent on the channel.
// You can add or remove single services by sending an array of size one and Op == ADD|REMOVE.
// For setting the state of the system to a given state for this source configuration, set Services as desired and Op to SET,
// which will reset the system state to that specified in this operation for this source channel.
// To remove all services, set Services to empty array and Op to SET
type ServiceUpdate struct {
    Services []api.Service
    Op       Operation
}

// EndpointsUpdate describes an operation of endpoints, sent on the channel.
// You can add or remove single endpoints by sending an array of size one and Op == ADD|REMOVE.
// For setting the state of the system to a given state for this source configuration, set Endpoints as desired and Op to SET,
// which will reset the system state to that specified in this operation for this source channel.
// To remove all endpoints, set Endpoints to empty array and Op to SET
type EndpointsUpdate struct {
    Endpoints []api.Endpoints
    Op        Operation
}

// ServiceConfigHandler is an abstract interface of objects which receive update notifications for the set of services.
type ServiceConfigHandler interface {
    // OnUpdate gets called when a configuration has been changed by one of the sources.
    // This is the union of all the configuration sources.
    OnUpdate(services []api.Service)
}

// EndpointsConfigHandler is an abstract interface of objects which receive update notifications for the set of endpoints.
type EndpointsConfigHandler interface {
    // OnUpdate gets called when endpoints configuration is changed for a given
    // service on any of the configuration sources. An example is when a new
    // service comes up, or when containers come up or down for an existing service.
    OnUpdate(endpoints []api.Endpoints)
}

// EndpointsConfig tracks a set of endpoints configurations.
// It accepts "set", "add" and "remove" operations of endpoints via channels, and invokes registered handlers on change.
type EndpointsConfig struct {
    mux     *config.Mux
    watcher *config.Watcher
    store   *endpointsStore
}
```
```go
type endpointsStore struct {
    endpointLock sync.RWMutex
    endpoints    map[string]map[string]api.Endpoints
    updates      chan<- struct{}
}
```
```go
// ServiceConfig tracks a set of service configurations.
// It accepts "set", "add" and "remove" operations of services via channels, and invokes registered handlers on change.
type ServiceConfig struct {
    mux     *config.Mux
    watcher *config.Watcher
    store   *serviceStore
}
```
```go
type serviceStore struct {
    serviceLock sync.RWMutex
    services    map[string]map[string]api.Service
    updates     chan<- struct{}
}
```
```go
// registryRoot is the key prefix for service configs in etcd.
const registryRoot = "registry/services"

// ConfigSourceEtcd communicates with a etcd via the client, and sends the change notification of services and endpoints to the specified channels.
type ConfigSourceEtcd struct {
    client           *etcd.Client
    serviceChannel   chan ServiceUpdate
    endpointsChannel chan EndpointsUpdate
    interval         time.Duration
}
```
```go
// serviceConfig is a deserialized form of the config file format which ConfigSourceFile accepts.
type serviceConfig struct {
    Services []struct {
        Name      string   `json: "name"`
        Port      int      `json: "port"`
        Endpoints []string `json: "endpoints"`
    } `json: "service"`
}

// ConfigSourceFile periodically reads service configurations in JSON from a file, and sends the services and endpoints defined in the file to the specified channels.
type ConfigSourceFile struct {
    serviceChannel   chan ServiceUpdate
    endpointsChannel chan EndpointsUpdate
    filename         string
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry

```go
// Package registry implements the storage and system logic for the core of the api server.
package registry
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry/binding

```go
// Package binding contains the middle layer logic for bindings.
// Bindings are objects containing instructions for how a pod ought to
// be bound to a host. This allows a registry object which supports this
// action (ApplyBinding) to be served through an apiserver.
package binding
```
```go
// Registry contains the functions needed to support a BindingStorage.
type Registry interface {
    // ApplyBinding should apply the binding. That is, it should actually
    // assign or place pod binding.PodID on machine binding.Host.
    ApplyBinding(binding *api.Binding) error
}
```
```go
// MockRegistry can be used for testing.
type MockRegistry struct {
    OnApplyBinding func(binding *api.Binding) error
}
```
```go
// REST implements the RESTStorage interface for bindings. When bindings are written, it
// changes the location of the affected pods. This information is eventually reflected
// in the pod's CurrentState.Host field.
type REST struct {
    registry Registry
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry/controller

```go
// Package controller provides Registry interface and it's RESTStorage
// implementation for storing ReplicationController api objects.
package controller
```
```go
// Registry is an interface for things that know how to store ReplicationControllers.
type Registry interface {
    ListControllers() (*api.ReplicationControllerList, error)
    WatchControllers(resourceVersion uint64) (watch.Interface, error)
    GetController(controllerID string) (*api.ReplicationController, error)
    CreateController(controller *api.ReplicationController) error
    UpdateController(controller *api.ReplicationController) error
    DeleteController(controllerID string) error
}
```
```go
// PodLister is anything that knows how to list pods.
type PodLister interface {
    ListPods(labels.Selector) (*api.PodList, error)
}
```
```go
// REST implements apiserver.RESTStorage for the replication controller service.
type REST struct {
    registry   Registry
    podLister  PodLister
    pollPeriod time.Duration
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry/endpoint

```go
// Package endpoint provides Registry interface and it's RESTStorage
// implementation for storing Endpoint api objects.
package endpoint
```
```go
// Registry is an interface for things that know how to store endpoints.
type Registry interface {
    ListEndpoints() (*api.EndpointsList, error)
    GetEndpoints(name string) (*api.Endpoints, error)
    WatchEndpoints(labels, fields labels.Selector, resourceVersion uint64) (watch.Interface, error)
    UpdateEndpoints(e *api.Endpoints) error
}
```
```go
// REST adapts endpoints into apiserver's RESTStorage model.
type REST struct {
    registry Registry
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry/etcd

```go
// Package etcd provides etcd backend implementation for storing
// PodRegistry, ControllerRegistry and ServiceRegistry api objects.
package etcd
```
```go
// TODO: Need to add a reconciler loop that makes sure that things in pods are reflected into
//       kubelet (and vice versa)

// Registry implements PodRegistry, ControllerRegistry and ServiceRegistry
// with backed by etcd.
type Registry struct {
    tools.EtcdHelper
    manifestFactory ManifestFactory
}
```
```go
type ManifestFactory interface {
    // Make a container object for a given pod, given the machine that the pod is running on.
    MakeManifest(machine string, pod api.Pod) (api.ContainerManifest, error)
}

type BasicManifestFactory struct {
    serviceRegistry service.Registry
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry/minion

```go
// Package minion provides Registry interface and implementation
// for storing Minions.
package minion
```
```go
type Clock interface {
    Now() time.Time
}

type SystemClock struct{}
```
```go
type CachingRegistry struct {
    delegate   Registry
    ttl        time.Duration
    minions    []string
    lastUpdate int64
    lock       sync.RWMutex
    clock      Clock
}
```
```go
type CloudRegistry struct {
    cloud   cloudprovider.Interface
    matchRE string
}
```
```go
type HealthyRegistry struct {
    delegate Registry
    client   health.HTTPGetInterface
    port     int
}
```
```go
var ErrDoesNotExist = fmt.Errorf("The requested resource does not exist.")

// Registry keeps track of a set of minions. Safe for concurrent reading/writing.
type Registry interface {
    List() (currentMinions []string, err error)
    Insert(minion string) error
    Delete(minion string) error
    Contains(minion string) (bool, error)
}
```
```go
type minionList struct {
    minions util.StringSet
    lock    sync.Mutex
}
```
```go
// REST implements the RESTStorage interface, backed by a MinionRegistry.
type REST struct {
    registry Registry
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry/pod

```go
// Package pod provides Registry interface and it's RESTStorage
// implementation for storing Pod api objects.
package pod
```
```go
// Registry is an interface implemented by things that know how to store Pod objects.
type Registry interface {
    // ListPods obtains a list of pods having labels which match selector.
    ListPods(selector labels.Selector) (*api.PodList, error)
    // ListPodsPredicate obtains a list of pods for which filter returns true.
    ListPodsPredicate(filter func(*api.Pod) bool) (*api.PodList, error)
    // Watch for new/changed/deleted pods
    WatchPods(resourceVersion uint64, filter func(*api.Pod) bool) (watch.Interface, error)
    // Get a specific pod
    GetPod(podID string) (*api.Pod, error)
    // Create a pod based on a specification.
    CreatePod(pod *api.Pod) error
    // Update an existing pod
    UpdatePod(pod *api.Pod) error
    // Delete an existing pod
    DeletePod(podID string) error
}
```
```go
// REST implements the RESTStorage interface in terms of a PodRegistry.
type REST struct {
    cloudProvider cloudprovider.Interface
    mu            sync.Mutex
    podCache      client.PodInfoGetter
    podInfoGetter client.PodInfoGetter
    podPollPeriod time.Duration
    registry      Registry
    minions       client.MinionInterface
}

type RESTConfig struct {
    CloudProvider cloudprovider.Interface
    PodCache      client.PodInfoGetter
    PodInfoGetter client.PodInfoGetter
    Registry      Registry
    Minions       client.MinionInterface
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry/service

```go
// Package service provides Registry interface and it's RESTStorage
// implementation for storing Service api objects.
package service
```
```go
// Registry is an interface for things that know how to store services.
type Registry interface {
    ListServices() (*api.ServiceList, error)
    CreateService(svc *api.Service) error
    GetService(name string) (*api.Service, error)
    DeleteService(name string) error
    UpdateService(svc *api.Service) error
    WatchServices(labels, fields labels.Selector, resourceVersion uint64) (watch.Interface, error)

    // TODO: endpoints and their implementation should be separated, setting endpoints should be
    // supported via the API, and the endpoints-controller should use the API to update endpoints.
    endpoint.Registry
}
```
```go
// REST adapts a service registry into apiserver's RESTStorage model.
type REST struct {
    registry Registry
    cloud    cloudprovider.Interface
    machines minion.Registry
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/registry/registrytest

```go
// Package registrytest provides tests for Registry implementations
// for storing Minions, Pods, Schedulers and Services.
package registrytest
```
```go
type MinionRegistry struct {
    Err     error
    Minion  string
    Minions []string
    sync.Mutex
}
```
```go
// TODO: Why do we have this AND MemoryRegistry?
type ControllerRegistry struct {
    Err         error
    Controllers *api.ReplicationControllerList
}
```
```go
type PodRegistry struct {
    Err  error
    Pod  *api.Pod
    Pods *api.PodList
    sync.Mutex

    mux *watch.Mux
}
```
```go
type Scheduler struct {
    Err     error
    Pod     api.Pod
    Machine string
}
```
```go
type ServiceRegistry struct {
    List          api.ServiceList
    Service       *api.Service
    Err           error
    Endpoints     api.Endpoints
    EndpointsList api.EndpointsList

    DeletedID string
    GottenID  string
    UpdatedID string
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/scheduler

```go
// Package scheduler contains a generic Scheduler interface and several
// implementations.
package scheduler
```
```go
// Scheduler is an interface implemented by things that know how to schedule pods
// onto machines.
type Scheduler interface {
    Schedule(api.Pod, MinionLister) (selectedMachine string, err error)
}
```
```go
// RandomScheduler chooses machines uniformly at random.
type RandomScheduler struct {
    random     *rand.Rand
    randomLock sync.Mutex
}
```
```go
// RandomFitScheduler is a Scheduler which schedules a Pod on a random machine which matches its requirement.
type RandomFitScheduler struct {
    podLister  PodLister
    random     *rand.Rand
    randomLock sync.Mutex
}
```
```go
// RoundRobinScheduler chooses machines in order.
type RoundRobinScheduler struct {
    currentIndex int
}
```
```go
// MinionLister interface represents anything that can list minions for a scheduler.
type MinionLister interface {
    List() (machines []string, err error)
}
```
```go
// PodLister interface represents anything that can list pods for a scheduler.
type PodLister interface {
    // TODO: make this exactly the same as client's ListPods() method...
    ListPods(labels.Selector) ([]api.Pod, error)
}
```
```go
// FakeMinionLister implements MinionLister on a []string for test purposes.
type FakeMinionLister []string
```
```go
// FakePodLister implements PodLister on an []api.Pods for test purposes.
type FakePodLister []api.Pod
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/service

```go
// Package service provides EndpointController implementation
// to manage and sync service endpoints.
package service
```
```go
// EndpointController manages service endpoints.
type EndpointController struct {
    client          *client.Client
    serviceRegistry service.Registry
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/tools

```go
// Package tools implements general tools which depend on the api package.
package tools
```
```go
const (
    EtcdErrorCodeNotFound      = 100
    EtcdErrorCodeTestFailed    = 101
    EtcdErrorCodeNodeExist     = 105
    EtcdErrorCodeValueRequired = 200
)

var (
    EtcdErrorNotFound      = &etcd.EtcdError{ErrorCode: EtcdErrorCodeNotFound}
    EtcdErrorTestFailed    = &etcd.EtcdError{ErrorCode: EtcdErrorCodeTestFailed}
    EtcdErrorNodeExist     = &etcd.EtcdError{ErrorCode: EtcdErrorCodeNodeExist}
    EtcdErrorValueRequired = &etcd.EtcdError{ErrorCode: EtcdErrorCodeValueRequired}
)

// EtcdClient is an injectable interface for testing.
type EtcdClient interface {
    AddChild(key, data string, ttl uint64) (*etcd.Response, error)
    Get(key string, sort, recursive bool) (*etcd.Response, error)
    Set(key, value string, ttl uint64) (*etcd.Response, error)
    Create(key, value string, ttl uint64) (*etcd.Response, error)
    CompareAndSwap(key, value string, ttl uint64, prevValue string, prevIndex uint64) (*etcd.Response, error)
    Delete(key string, recursive bool) (*etcd.Response, error)
    // I'd like to use directional channels here (e.g. <-chan) but this interface mimics
    // the etcd client interface which doesn't, and it doesn't seem worth it to wrap the api.
    Watch(prefix string, waitIndex uint64, recursive bool, receiver chan *etcd.Response, stop chan bool) (*etcd.Response, error)
}

// EtcdGetSet interface exposes only the etcd operations needed by EtcdHelper.
type EtcdGetSet interface {
    Get(key string, sort, recursive bool) (*etcd.Response, error)
    Set(key, value string, ttl uint64) (*etcd.Response, error)
    Create(key, value string, ttl uint64) (*etcd.Response, error)
    Delete(key string, recursive bool) (*etcd.Response, error)
    CompareAndSwap(key, value string, ttl uint64, prevValue string, prevIndex uint64) (*etcd.Response, error)
    Watch(prefix string, waitIndex uint64, recursive bool, receiver chan *etcd.Response, stop chan bool) (*etcd.Response, error)
}

// EtcdHelper offers common object marshalling/unmarshalling operations on an etcd client.
type EtcdHelper struct {
    Client EtcdGetSet
    Codec  runtime.Codec
    // optional, no atomic operations can be performed without this interface
    ResourceVersioner runtime.ResourceVersioner
}
```
```go
// FilterFunc is a predicate which takes an API object and returns true
// iff the object should remain in the set.
type FilterFunc func(obj runtime.Object) bool
```
```go
// TransformFunc attempts to convert an object to another object for use with a watcher.
type TransformFunc func(runtime.Object) (runtime.Object, error)

// etcdWatcher converts a native etcd watch to a watch.Interface.
type etcdWatcher struct {
    encoding  runtime.Codec
    versioner runtime.ResourceVersioner
    transform TransformFunc

    list   bool // If we're doing a recursive watch, should be true.
    filter FilterFunc

    etcdIncoming  chan *etcd.Response
    etcdStop      chan bool
    etcdCallEnded chan struct{}

    outgoing chan watch.Event
    userStop chan struct{}
    stopped  bool
    stopLock sync.Mutex

    // Injectable for testing. Send the event down the outgoing channel.
    emit func(watch.Event)
}
```
```go
type EtcdResponseWithError struct {
    R *etcd.Response
    E error
    // if N is non-null, it will be assigned into the map after this response is used for an operation
    N *EtcdResponseWithError
}

// TestLogger is a type passed to Test functions to support formatted test logs.
type TestLogger interface {
    Errorf(format string, args ...interface{})
    Logf(format string, args ...interface{})
}

type FakeEtcdClient struct {
    watchCompletedChan chan bool

    Data                 map[string]EtcdResponseWithError
    DeletedKeys          []string
    expectNotFoundGetSet map[string]struct{}
    sync.Mutex
    Err         error
    t           TestLogger
    Ix          int
    TestIndex   bool
    ChangeIndex uint64

    // Will become valid after Watch is called; tester may write to it. Tester may
    // also read from it to verify that it's closed after injecting an error.
    WatchResponse chan *etcd.Response
    WatchIndex    uint64
    // Write to this to prematurely stop a Watch that is running in a goroutine.
    WatchInjectError chan<- error
    WatchStop        chan<- bool
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/tools

```go
// Package tools implements general tools which depend on the api package.
package tools
```
```go
const (
    EtcdErrorCodeNotFound      = 100
    EtcdErrorCodeTestFailed    = 101
    EtcdErrorCodeNodeExist     = 105
    EtcdErrorCodeValueRequired = 200
)

var (
    EtcdErrorNotFound      = &etcd.EtcdError{ErrorCode: EtcdErrorCodeNotFound}
    EtcdErrorTestFailed    = &etcd.EtcdError{ErrorCode: EtcdErrorCodeTestFailed}
    EtcdErrorNodeExist     = &etcd.EtcdError{ErrorCode: EtcdErrorCodeNodeExist}
    EtcdErrorValueRequired = &etcd.EtcdError{ErrorCode: EtcdErrorCodeValueRequired}
)

// EtcdClient is an injectable interface for testing.
type EtcdClient interface {
    AddChild(key, data string, ttl uint64) (*etcd.Response, error)
    Get(key string, sort, recursive bool) (*etcd.Response, error)
    Set(key, value string, ttl uint64) (*etcd.Response, error)
    Create(key, value string, ttl uint64) (*etcd.Response, error)
    CompareAndSwap(key, value string, ttl uint64, prevValue string, prevIndex uint64) (*etcd.Response, error)
    Delete(key string, recursive bool) (*etcd.Response, error)
    // I'd like to use directional channels here (e.g. <-chan) but this interface mimics
    // the etcd client interface which doesn't, and it doesn't seem worth it to wrap the api.
    Watch(prefix string, waitIndex uint64, recursive bool, receiver chan *etcd.Response, stop chan bool) (*etcd.Response, error)
}

// EtcdGetSet interface exposes only the etcd operations needed by EtcdHelper.
type EtcdGetSet interface {
    Get(key string, sort, recursive bool) (*etcd.Response, error)
    Set(key, value string, ttl uint64) (*etcd.Response, error)
    Create(key, value string, ttl uint64) (*etcd.Response, error)
    Delete(key string, recursive bool) (*etcd.Response, error)
    CompareAndSwap(key, value string, ttl uint64, prevValue string, prevIndex uint64) (*etcd.Response, error)
    Watch(prefix string, waitIndex uint64, recursive bool, receiver chan *etcd.Response, stop chan bool) (*etcd.Response, error)
}

// EtcdHelper offers common object marshalling/unmarshalling operations on an etcd client.
type EtcdHelper struct {
    Client EtcdGetSet
    Codec  runtime.Codec
    // optional, no atomic operations can be performed without this interface
    ResourceVersioner runtime.ResourceVersioner
}
```
```go
// FilterFunc is a predicate which takes an API object and returns true
// iff the object should remain in the set.
type FilterFunc func(obj runtime.Object) bool
```
```go
// TransformFunc attempts to convert an object to another object for use with a watcher.
type TransformFunc func(runtime.Object) (runtime.Object, error)

// etcdWatcher converts a native etcd watch to a watch.Interface.
type etcdWatcher struct {
    encoding  runtime.Codec
    versioner runtime.ResourceVersioner
    transform TransformFunc

    list   bool // If we're doing a recursive watch, should be true.
    filter FilterFunc

    etcdIncoming  chan *etcd.Response
    etcdStop      chan bool
    etcdCallEnded chan struct{}

    outgoing chan watch.Event
    userStop chan struct{}
    stopped  bool
    stopLock sync.Mutex

    // Injectable for testing. Send the event down the outgoing channel.
    emit func(watch.Event)
}
```
```go
type EtcdResponseWithError struct {
    R *etcd.Response
    E error
    // if N is non-null, it will be assigned into the map after this response is used for an operation
    N *EtcdResponseWithError
}

// TestLogger is a type passed to Test functions to support formatted test logs.
type TestLogger interface {
    Errorf(format string, args ...interface{})
    Logf(format string, args ...interface{})
}

type FakeEtcdClient struct {
    watchCompletedChan chan bool

    Data                 map[string]EtcdResponseWithError
    DeletedKeys          []string
    expectNotFoundGetSet map[string]struct{}
    sync.Mutex
    Err         error
    t           TestLogger
    Ix          int
    TestIndex   bool
    ChangeIndex uint64

    // Will become valid after Watch is called; tester may write to it. Tester may
    // also read from it to verify that it's closed after injecting an error.
    WatchResponse chan *etcd.Response
    WatchIndex    uint64
    // Write to this to prematurely stop a Watch that is running in a goroutine.
    WatchInjectError chan<- error
    WatchStop        chan<- bool
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/util

```go
// Package util implements various utility functions used in both testing and implementation
// of Kubernetes. Package util may not depend on any other package in the Kubernetes
// package tree.
package util
```
```go
// TestInterface is a simple interface providing Errorf, to make injection for
// testing easier (insert 'yo dawg' meme here).
type TestInterface interface {
    Errorf(format string, args ...interface{})
}

// LogInterface is a simple interface to allow injection of Logf to report serving errors.
type LogInterface interface {
    Logf(format string, args ...interface{})
}

// FakeHandler is to assist in testing HTTP requests. Notice that FakeHandler is
// not thread safe and you must not direct traffic to except for the request
// you want to test. You can do this by hiding it in an http.ServeMux.
type FakeHandler struct {
    RequestReceived *http.Request
    RequestBody     string
    StatusCode      int
    ResponseBody    string
    // For logging - you can use a *testing.T
    // This will keep log messages associated with the test.
    T LogInterface
}
```
```go
type StringList []string
```
```go
var logFlushFreq = flag.Duration("log_flush_frequency", 5*time.Second, "Maximum number of seconds between log flushes")

// TODO(thockin): This is temporary until we agree on log dirs and put those into each cmd.
func init() {
    flag.Set("logtostderr", "true")
}

// GlogWriter serves as a bridge between the standard log package and the glog package.
type GlogWriter struct{}
```
```go
type empty struct{}

// StringSet is a set of strings, implemented via map[string]struct{} for minimal memory consumption.
type StringSet map[string]empty
```
```go
// Time is a wrapper around time.Time which supports correct
// marshaling to YAML and JSON.  Wrappers are provided for many
// of the factory methods that the time package offers.
type Time struct {
    time.Time
}
```
```go
// For testing, bypass HandleCrash.
var ReallyCrash bool
```
```go
// IntOrString is a type that can hold an int or a string.  When used in
// JSON or YAML marshalling and unmarshalling, it produces or consumes the
// inner type.  This allows you to have, for example, a JSON field that can
// accept a name or number.
type IntOrString struct {
    Kind   IntstrKind
    IntVal int
    StrVal string
}

// IntstrKind represents the stored type of IntOrString.
type IntstrKind int

const (
    IntstrInt    IntstrKind = iota // The IntOrString holds an int.
    IntstrString                   // The IntOrString holds a string.
)
```
```go
const dnsLabelFmt string = "[a-z0-9]([-a-z0-9]*[a-z0-9])?"

var dnsLabelRegexp = regexp.MustCompile("^" + dnsLabelFmt + "$")

const dnsLabelMaxLength int = 63
```
```go
const dnsSubdomainFmt string = dnsLabelFmt + "(\\." + dnsLabelFmt + ")*"

var dnsSubdomainRegexp = regexp.MustCompile("^" + dnsSubdomainFmt + "$")

const dnsSubdomainMaxLength int = 253
```
```go
const cIdentifierFmt string = "[A-Za-z_][A-Za-z0-9_]*"

var cIdentifierRegexp = regexp.MustCompile("^" + cIdentifierFmt + "$")
```
```go
const dns952IdentifierFmt string = "[a-z]([-a-z0-9]*[a-z0-9])?"

var dns952Regexp = regexp.MustCompile("^" + dns952IdentifierFmt + "$")

const dns952MaxLength = 24
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/util/config

```go
// Package config provides utility objects for decoupling sources of configuration and the
// actual configuration state. Consumers must implement the Merger interface to unify
// the sources of change into an object.
package config
```
```go
type Merger interface {
    // Invoked when a change from a source is received.  May also function as an incremental
    // merger if you wish to consume changes incrementally.  Must be reentrant when more than
    // one source is defined.
    Merge(source string, update interface{}) error
}

// MergeFunc implements the Merger interface
type MergeFunc func(source string, update interface{}) error
```
```go
// Mux is a class for merging configuration from multiple sources.  Changes are
// pushed via channels and sent to the merge function.
type Mux struct {
    // Invoked when an update is sent to a source.
    merger Merger

    // Sources and their lock.
    sourceLock sync.RWMutex
    // Maps source names to channels
    sources map[string]chan interface{}
}
```
```go
// Accessor is an interface for retrieving the current merge state.
type Accessor interface {
    // MergedState returns a representation of the current merge state.
    // Must be reentrant when more than one source is defined.
    MergedState() interface{}
}

// AccessorFunc implements the Accessor interface.
type AccessorFunc func() interface{}
```
```go
type Listener interface {
    // OnUpdate is invoked when a change is made to an object.
    OnUpdate(instance interface{})
}

// ListenerFunc receives a representation of the change or object.
type ListenerFunc func(instance interface{})
```
```go
type Watcher struct {
    // Listeners for changes and their lock.
    listenerLock sync.RWMutex
    listeners    []Listener
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/util/config

```go
// Package wait provides tools for polling or listening for changes
// to a condition.
package wait
```
```go
// ErrWaitTimeout is returned when the condition exited without success
var ErrWaitTimeout = errors.New("timed out waiting for the condition")

// ConditionFunc returns true if the condition is satisfied, or an error
// if the loop should be aborted.
type ConditionFunc func() (done bool, err error)
```
```go
// WaitFunc creates a channel that receives an item every time a test
// should be executed and is closed when the last test should be invoked.
type WaitFunc func() <-chan struct{}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/version

```go
// Package version supplies version information collected at build time to
// kubernetes components.
package version
```
```go
var (
    // TODO: Deprecate gitMajor and gitMinor, use only gitVersion instead.
    gitMajor     string = "0"              // major version, always numeric
    gitMinor     string = "3"              // minor version, numeric possibly followed by "+"
    gitVersion   string = "v0.3"           // version from git, output of $(git describe)
    gitCommit    string = ""               // sha1 from git, output of $(git rev-parse HEAD)
    gitTreeState string = "not a git tree" // state of git tree, either "clean" or "dirty"
)
```
```go
// Info contains versioning information.
// TODO: Add []string of api versions supported? It's still unclear
// how we'll want to distribute that information.
type Info struct {
    Major        string `json:"major" yaml:"major"`
    Minor        string `json:"minor" yaml:"minor"`
    GitVersion   string `json:"gitVersion" yaml:"gitVersion"`
    GitCommit    string `json:"gitCommit" yaml:"gitCommit"`
    GitTreeState string `json:"gitTreeState" yaml:"gitTreeState"`
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/version/verflag

```go
type versionValue int
```
```go
const (
    VersionFalse versionValue = 0
    VersionTrue  versionValue = 1
    VersionRaw   versionValue = 2
)
```
```go
const strRawVersion string = "raw"
```
```go
var (
    versionFlag = Version("version", VersionFalse, "Print version information and quit")
)
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/volume

```go
// Package volume includes internal representations of external volume types
// as well as utility methods required to mount/unmount volumes to kubelets.
package volume
```
```go
var ErrUnsupportedVolumeType = errors.New("unsupported volume type")

// Interface is a directory used by pods or hosts.
// All method implementations of methods in the volume interface must be idempotent.
type Interface interface {
    // GetPath returns the directory path the volume is mounted to.
    GetPath() string
}

// Builder interface provides method to set up/mount the volume.
type Builder interface {
    // Uses Interface to provide the path for Docker binds.
    Interface
    // SetUp prepares and mounts/unpacks the volume to a directory path.
    SetUp() error
}

// Cleaner interface provides method to cleanup/unmount the volumes.
type Cleaner interface {
    // TearDown unmounts the volume and removes traces of the SetUp procedure.
    TearDown() error
}

// HostDirectory volumes represent a bare host directory mount.
// The directory in Path will be directly exposed to the container.
type HostDirectory struct {
    Path string
}
```
```go
// EmptyDirectory volumes are temporary directories exposed to the pod.
// These do not persist beyond the lifetime of a pod.
type EmptyDirectory struct {
    Name    string
    PodID   string
    RootDir string
}
```

### github.com/GoogleCloudPlatform/kubernetes/pkg/watch

```go
// Package watch contains a generic watchable interface, and a fake for
// testing code that uses the watch interface.
package watch
```
```go
// Interface can be implemented by anything that knows how to watch and report changes.
type Interface interface {
    // Stops watching. Will close the channel returned by ResultChan(). Releases
    // any resources used by the watch.
    Stop()

    // Returns a chan which will receive all the events. If an error occurs
    // or Stop() is called, this channel will be closed, in which case the
    // watch should be completely cleaned up.
    ResultChan() <-chan Event
}
```
```go
// EventType defines the possible types of events.
type EventType string
```
```go
const (
    Added    EventType = "ADDED"
    Modified EventType = "MODIFIED"
    Deleted  EventType = "DELETED"
)
```
```go
type Event struct {
    Type EventType

    // If Type == Deleted, then this is the state of the object
    // immediately before deletion.
    Object runtime.Object
}
```
```go
// FakeWatcher lets you test anything that consumes a watch.Interface; threadsafe.
type FakeWatcher struct {
    result  chan Event
    Stopped bool
    sync.Mutex
}
```
```go
// Mux distributes event notifications among any number of watchers. Every event
// is delivered to every watcher.
type Mux struct {
    lock sync.Mutex

    watchers    map[int64]*muxWatcher
    nextWatcher int64

    incoming chan Event
}
```
```go
// muxWatcher handles a single watcher of a mux
type muxWatcher struct {
    result  chan Event
    stopped chan struct{}
    stop    sync.Once
    id      int64
    m       *Mux
}
```
```go
// Decoder allows StreamWatcher to watch any stream for which a Decoder can be written.
type Decoder interface {
    // Decode should return the type of event, the decoded object, or an error.
    // An error will cause StreamWatcher to call Close(). Decode should block until
    // it has data or an error occurs.
    Decode() (action EventType, object runtime.Object, err error)

    // Close should close the underlying io.Reader, signalling to the source of
    // the stream that it is no longer being watched. Close() must cause any
    // outstanding call to Decode() to return with an error of some sort.
    Close()
}
```
```go
// StreamWatcher turns any stream for which you can write a Decoder interface
// into a watch.Interface.
type StreamWatcher struct {
    source Decoder
    result chan Event
    sync.Mutex
    stopped bool
}
```
```go
// FilterFunc should take an event, possibly modify it in some way, and return
// the modified event. If the event should be ignored, then return keep=false.
type FilterFunc func(in Event) (out Event, keep bool)
```
```go
type filteredWatch struct {
    incoming Interface
    result   chan Event
    f        FilterFunc
}
```

