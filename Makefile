.PHONY: cluster delete ingress strimzi kafka

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

kafka:
	kubectl apply -f kafka-cluster.yaml

test-internal:
	@kubectl view-secret -n streaming admin user.p12 > user.p12
	@kubectl -n streaming port-forward services/cluster-development-kafka-bootstrap 9092 & PORT_FORWARD_PID="$$!" && \
	kcat -b 127.0.0.1:9092 -L -J -X "ssl.keystore.location=user.p12" -X "ssl.keystore.password=$$(kubectl view-secret -n streaming admin user.password)" | jq && \
	kill -9 "$$PORT_FORWARD_PID"
	@rm -rf user.p12

test-services:
	@kubectl view-secret -n streaming admin user.p12 > user.p12
	@kubectl -n streaming port-forward services/cluster-development-kafka-expose-bootstrap 9094 & PORT_FORWARD_PID="$$!" && \
	kubectl view-secret -n streaming cluster-development-cluster-ca-cert ca.crt | kcat -b kafka.127.0.0.1.nip.io:9094 -L -J -X 'security.protocol=ssl' -X "ssl.ca.location=/dev/stdin" -X "ssl.keystore.location=user.p12" -X "ssl.keystore.password=$$(kubectl view-secret -n streaming admin user.password)" |jq && \
	kill -9 "$$PORT_FORWARD_PID"
	@rm -rf user.p12

test-ingress:
	@kubectl view-secret -n streaming admin user.p12 > user.p12
	@kubectl port-forward -n ingress-system services/ingress-nginx-controller 27017:443 & PORT_FORWARD_PID="$$!" && \
	kubectl view-secret -n streaming cluster-development-cluster-ca-cert ca.crt | kcat -b kafka.127.0.0.1.nip.io:27017 -L -J -X 'security.protocol=ssl' -X "ssl.ca.location=/dev/stdin" -X "ssl.keystore.location=user.p12" -X "ssl.keystore.password=$$(kubectl view-secret -n streaming admin user.password)" |jq && \
	kill -9 "$$PORT_FORWARD_PID"
	@rm -rf user.p12

test:
	@kubectl view-secret -n streaming admin user.p12 > user.p12 && \
	kubectl view-secret -n streaming cluster-development-cluster-ca-cert ca.crt | kcat -b kafka.127.0.0.1.nip.io:443 -L -J -X 'security.protocol=ssl' -X "ssl.ca.location=/dev/stdin" -X "ssl.keystore.location=user.p12" -X "ssl.keystore.password=$$(kubectl view-secret -n streaming admin user.password)" |jq && \
	rm -rf user.p12

delete:
	kind delete clusters $(CLUSTER_NAME)
