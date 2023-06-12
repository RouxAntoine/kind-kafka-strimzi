.PHONY: cluster delete

CLUSTER_NAME=cluster-dev

cluster:
	kind create cluster --config=kind-config.yaml
	kubectl taint node cluster-dev-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

delete:
	kind delete clusters $(CLUSTER_NAME)
