.PHONY: cluster delete ingress

INGRESS_NS=ingress-system
CLUSTER_NAME=cluster-dev

cluster:
	kind create cluster --config=kind-config.yaml
	kubectl taint node cluster-dev-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

ingress:
	helm upgrade --install ingress-nginx ingress-nginx \
	--repo https://kubernetes.github.io/ingress-nginx \
	--namespace $(INGRESS_NS) --create-namespace \
	--values nginx-ingress-values.yaml

delete:
	kind delete clusters $(CLUSTER_NAME)
