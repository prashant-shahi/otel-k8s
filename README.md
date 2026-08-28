# otel-k8s

Vendor-neutral Helm charts for collecting Kubernetes telemetry with
[OpenTelemetry](https://opentelemetry.io/) and shipping it over OTLP to any
backend that speaks the protocol.

## Charts

| Chart | Description |
| --- | --- |
| [`k8s-infra`](./charts/k8s-infra) | DaemonSet and Deployment OpenTelemetry Collectors that gather node and pod metrics, container logs, and Kubernetes events. |
| [`otel-gateway`](./charts/otel-gateway) | An OpenTelemetry gateway collector that fronts OTLP traffic for a cluster. |

## TL;DR

```bash
helm repo add otel-k8s https://prashant-shahi.github.io/otel-k8s
helm repo update
helm install my-release otel-k8s/k8s-infra \
  --set otelCollectorEndpoint=https://otlp.example.com:443
```

That lands in whatever namespace your current context points at. To put it
somewhere else, add `-n <namespace> --create-namespace`.

## Before you begin

### Set up a Kubernetes cluster

The quickest way to get a staging or production cluster going is with
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/),
[AWS Elastic Kubernetes Service](https://aws.amazon.com/eks/) or
[Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/),
following their respective quick-start guides.

For other cloud platforms, bare-metal servers, or a local machine, see the
Kubernetes [getting started guide](https://kubernetes.io/docs/setup/).

For local development, a lightweight cluster works well. Try
[kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation),
[k3d](https://k3d.io/#installation) or
[minikube](https://minikube.sigs.k8s.io/docs/start/).

### Install kubectl

`kubectl` is the [Kubernetes](https://kubernetes.io/) command-line tool. You
use it to deploy applications, inspect and manage cluster resources, and read
logs. Installation instructions are
[here](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

### Install Helm

[Helm](https://helm.sh/) manages Kubernetes charts, which are packages of
pre-configured Kubernetes resources. Installation instructions are
[here](https://helm.sh/docs/intro/install/).

## Choosing a backend

The charts do not assume any particular vendor. Point them at your OTLP
endpoint and send whatever authentication header that backend expects.

```yaml
otelCollectorEndpoint: https://otlp.example.com:443
otelInsecure: false

# Stored in a Secret and exposed to the collector as ${env:OTEL_API_KEY}
apiKey: "<your-api-key>"

otelExporterHeaders:
  authorization: "Bearer ${env:OTEL_API_KEY}"
```

The [`k8s-infra` chart README](./charts/k8s-infra/README.md) lists every value
you can set.

## Development

```bash
make dev-install     # install charts/k8s-infra into the configured namespace
make test            # run helm unit tests
make chart-docs      # regenerate chart READMEs from values.yaml
```

## Contributing

See the [contributing guide](./CONTRIBUTING.md).

## License

MIT License. See [LICENSE](./LICENSE).
