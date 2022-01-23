helm install --dry-run --debug rabbitmq . --values values-pvc-rabbitmq.yaml -n  rabbitmq

helm install rabbitmq . --values values-pvc-rabbitmq.yaml -n  rabbitmq

helm delete rabbitmq -n rabbitmq

kubectl delete pvc data-rabbitmq-rabbitmq-ha-0 data-rabbitmq-rabbitmq-ha-1 data-rabbitmq-rabbitmq-ha-2 -n rabbitmq
