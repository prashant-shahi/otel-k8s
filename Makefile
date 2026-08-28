RELEASE_NAME := my-release
NAMESPACE := platform # k8s namespace for installing the chart
CHART := charts/k8s-infra

delete-namespace:
	kubectl delete namespace $(NAMESPACE)

# print resulting manifests to console without applying them
debug:
	helm install --dry-run --debug $(RELEASE_NAME) $(CHART)

# install the chart to configured namespace
install:
	helm upgrade -i $(RELEASE_NAME) -n $(NAMESPACE) --create-namespace $(CHART)

# uninstall the chart and resources from configured namespace
uninstall:
	helm uninstall -n $(NAMESPACE) $(RELEASE_NAME)

# delete all resources from configured namespace
delete: uninstall
	kubectl delete all,pvc,cm --all -n $(NAMESPACE)

upgrade:
	helm upgrade $(RELEASE_NAME) -n $(NAMESPACE) --create-namespace $(CHART)

list:
	kubectl get all -n $(NAMESPACE)

list-all:
	kubectl get all,pvc,cm -n $(NAMESPACE)

# install the local development chart to configured namespace
dev-install: install

re-install: delete install

purge: delete delete-namespace

# run helm unit tests for all charts
# requires: helm plugin install https://github.com/helm-unittest/helm-unittest
test:
	helm unittest charts/k8s-infra

# lint all charts
lint:
	ct lint --config ct.yaml

# generate docs for specified charts with respective templates
# Usage: make chart-docs CHARTS=chart1,chart2
# Example: make chart-docs CHARTS=charts/k8s-infra
CHARTS ?= charts/k8s-infra
HELM_DOCS = go run github.com/norwoodj/helm-docs/cmd/helm-docs@v1.14.2
chart-docs:
	$(HELM_DOCS) --chart-search-root=charts --template-files=README.md.gotmpl --chart-to-generate=$(CHARTS) --sort-values-order=file
