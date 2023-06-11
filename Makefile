.PHONY: cluster delete ingress strimzi

INGRESS_NS=ingress-system
CLUSTER_NAME=cluster-dev
STRIMZI_NS=kafka-system

cluster:
	kind create cluster --config=kind-config.yaml
	kubectl taint node cluster-dev-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

ingress:
	helm upgrade --install ingress-nginx ingress-nginx \
	--repo https://kubernetes.github.io/ingress-nginx \
	--namespace $(INGRESS_NS) --create-namespace \
	--values nginx-ingress-values.yaml

strimzi:
	kubectl apply -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.35.1/strimzi-crds-0.35.1.yaml
	helm upgrade --install strimzi-operator strimzi-kafka-operator \
		--namespace $(STRIMZI_NS) --create-namespace \
		--repo https://strimzi.io/charts \
		--set watchAnyNamespace=true
#		--set featureGates=+UseKRaft

delete:
	kind delete clusters $(CLUSTER_NAME)
