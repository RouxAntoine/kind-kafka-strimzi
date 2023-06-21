# kind x strimzi

Sample project of kafka cluster deployed with strimzi on kind kubernetes cluster

setup kind kubernetes cluster

```shell
$ make cluster
```

setup nginx ingress controller

```shell
$ make ingress
```

setup strimzi operator

```shell
$ make strimzi
```

create kafka cluster

```shell
$ make kafka
```
delete kubernetes cluster and everything contained

```shell
$ make delete
```
