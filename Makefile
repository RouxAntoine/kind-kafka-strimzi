.PHONY: cluster delete ingress strimzi kafka

INGRESS_NS=ingress-system
CLUSTER_NAME=cluster-dev
STRIMZI_NS=kafka-system
KAFKA_NS=streaming

cluster:
	kind create cluster --config=kind-config.yaml
	kubectl taint node cluster-dev-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

ingress:
	helm upgrade --install ingress-nginx ingress-nginx \
	--repo https://kubernetes.github.io/ingress-nginx \
	--namespace $(INGRESS_NS) --create-namespace \
	--values nginx-ingress-values.yaml

strimzi:
	kubectl apply -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.40.0/strimzi-crds-0.40.0.yaml
	helm upgrade --version 0.40.0 --install strimzi-operator strimzi-kafka-operator \
		--namespace $(STRIMZI_NS) --create-namespace \
		--repo https://strimzi.io/charts \
		--set watchAnyNamespace=true
#		--set featureGates=+UseKRaft

kafka:
	kubectl apply -f kafka/cluster.yaml
	kubectl apply -f kafka/user.yaml
kafka-node-pool:
	kubectl apply -f kafka/cluster-node-pool.yaml
	kubectl apply -f kafka/user.yaml

ui:
	@kubectl view-secret -n $(KAFKA_NS) admin user.p12 > user.p12
	@kubectl view-secret -n $(KAFKA_NS) cluster-development-cluster-ca-cert ca.crt > ca.crt
	@keytool -import -noprompt -alias ca -file ./ca.crt -keystore kafka.truststore.jks -storepass changeme
	@kubectl delete -n $(KAFKA_NS) configmap truststore | true
	@kubectl create -n $(KAFKA_NS) configmap truststore --from-file kafka.truststore.jks
	sed "s/PASSWORD/$$(kubectl view-secret -n $(KAFKA_NS) admin user.password)/g" kafka/kafka-ui.yaml | helm upgrade --version 1.4.0 --install kafka-ui kafka-ui \
		--namespace $(KAFKA_NS) --create-namespace \
		--repo https://ui.charts.kafbat.io \
		--values /dev/stdin
	@rm -rf user.p12
	@rm -rf ca.crt
	@rm -rf kafka.truststore.jks

test-internal:
	@kubectl view-secret -n $(KAFKA_NS) admin user.p12 > user.p12
	@kubectl -n $(KAFKA_NS) port-forward services/cluster-development-kafka-bootstrap 9092 & PORT_FORWARD_PID="$$!" && \
	kcat -b 127.0.0.1:9092 -L -J -X "ssl.keystore.location=user.p12" -X "ssl.keystore.password=$$(kubectl view-secret -n streaming admin user.password)" | jq && \
	kill -9 "$$PORT_FORWARD_PID"
	@rm -rf user.p12

test-services:
	@kubectl view-secret -n $(KAFKA_NS) admin user.p12 > user.p12
	@kubectl -n $(KAFKA_NS) port-forward services/cluster-development-kafka-expose-bootstrap 9094 & PORT_FORWARD_PID="$$!" && \
	kubectl view-secret -n $(KAFKA_NS) cluster-development-cluster-ca-cert ca.crt | kcat -b kafka.127.0.0.1.nip.io:9094 -L -J -X 'security.protocol=ssl' -X "ssl.ca.location=/dev/stdin" -X "ssl.keystore.location=user.p12" -X "ssl.keystore.password=$$(kubectl view-secret -n $(KAFKA_NS) admin user.password)" |jq && \
	kill -9 "$$PORT_FORWARD_PID"
	@rm -rf user.p12

test-ingress:
	@kubectl view-secret -n $(KAFKA_NS) admin user.p12 > user.p12
	@kubectl port-forward -n ingress-system services/ingress-nginx-controller 27017:443 & PORT_FORWARD_PID="$$!" && \
	kubectl view-secret -n $(KAFKA_NS) cluster-development-cluster-ca-cert ca.crt | kcat -b kafka.127.0.0.1.nip.io:27017 -L -J -X 'security.protocol=ssl' -X "ssl.ca.location=/dev/stdin" -X "ssl.keystore.location=user.p12" -X "ssl.keystore.password=$$(kubectl view-secret -n $(KAFKA_NS) admin user.password)" |jq && \
	kill -9 "$$PORT_FORWARD_PID"
	@rm -rf user.p12

test:
	@kubectl view-secret -n $(KAFKA_NS) admin user.p12 > user.p12 && \
	kubectl view-secret -n $(KAFKA_NS) cluster-development-cluster-ca-cert ca.crt | kcat -b kafka.127.0.0.1.nip.io:443 -L -J -X 'security.protocol=ssl' -X "ssl.ca.location=/dev/stdin" -X "ssl.keystore.location=user.p12" -X "ssl.keystore.password=$$(kubectl view-secret -n $(KAFKA_NS) admin user.password)" |jq && \
	rm -rf user.p12

create-topic:
	kubectl apply -f kafka/topic.yaml

delete:
	kind delete clusters $(CLUSTER_NAME)

rebalance-remove:
	kubectl -n $(KAFKA_NS) apply -f kafka/rebalance-remove.yaml

rebalance-delete-remove:
	kubectl -n $(KAFKA_NS) delete -f kafka/rebalance-remove.yaml

rebalance-approve-remove:
	kubectl -n $(KAFKA_NS) annotate kafkarebalances.kafka.strimzi.io remove-node strimzi.io/rebalance=approve

rebalance-full:
	kubectl -n $(KAFKA_NS) apply -f kafka/rebalance-full.yaml

rebalance-delete-full:
	kubectl -n $(KAFKA_NS) delete -f kafka/rebalance-full.yaml

rebalance-refresh-full:
	kubectl -n $(KAFKA_NS) annotate kafkarebalances.kafka.strimzi.io rebalance-all-node strimzi.io/rebalance=refresh

rebalance-add:
	kubectl -n $(KAFKA_NS) apply -f kafka/rebalance-add.yaml

rebalance-delete-add:
	kubectl -n $(KAFKA_NS) delete -f kafka/rebalance-add.yaml
