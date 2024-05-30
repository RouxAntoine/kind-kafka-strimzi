# kind related stuff

Sample project to setup some stuff on kind kubernetes cluster

setup kind kubernetes cluster

```shell
$ make cluster
```

setup nginx ingress controller

```shell
$ make ingress
```

delete kubernetes cluster and everything contained

```shell
$ make delete
```

## kind x strimzi

Sample project of kafka cluster deployed with strimzi on kind kubernetes cluster

setup strimzi operator

```shell
$ make strimzi
```

create kafka cluster

```shell
$ make kafka
```

Test command

```shell
$ make test-internal # port-forward internal broker listener
$ make test-services # port-forward exposed broker listener through service
$ make test-ingress # port-forward ingress controller service
$ make test # direct access with kind port-mapping
```

---

doc:

architecture layer

![](./docs/architecture.png)
