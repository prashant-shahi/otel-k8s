# otel-k8s

Vendor-neutral Helm charts for collecting Kubernetes telemetry with
[OpenTelemetry](https://opentelemetry.io/) and exporting it over OTLP to any
compatible observability backend.

## Charts

| Chart | Description |
| --- | --- |
| [`k8s-infra`](./charts/k8s-infra) | DaemonSet + Deployment OpenTelemetry Collectors that collect node/pod metrics, container logs and Kubernetes events. |
| [`otel-gateway`](./charts/otel-gateway) | An OpenTelemetry gateway collector that fronts OTLP traffic for a cluster. |

## TL;DR

```bash
helm install -n platform --create-namespace my-release ./charts/k8s-infra --set otelCollectorEndpoint=https://otlp.example.com:443
```

## Before you begin

### Set up a Kubernetes cluster

The quickest way to set up a staging/production Kubernetes cluster is with [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/),
[AWS Elastic Kubernetes Service](https://aws.amazon.com/eks/) or [Azure Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/)
using their respective quick-start guides.

For setting up Kubernetes on other cloud platforms, bare-metal servers, or a local machine, refer to the Kubernetes
[getting started guide](https://kubernetes.io/docs/setup/).

For local development, a lightweight cluster works well:
[kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation),
[k3d](https://k3d.io/#installation) or
[minikube](https://minikube.sigs.k8s.io/docs/start/).

### Install kubectl

The [Kubernetes](https://kubernetes.io/) command-line tool, `kubectl`, allows you to
run commands against Kubernetes clusters. You can use kubectl to deploy applications,
inspect and manage cluster resources, and view logs.

To install `kubectl`, follow the instructions [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

### Install Helm

[Helm](https://helm.sh/) is a tool for managing Kubernetes charts. Charts are packages
of pre-configured Kubernetes resources.

To install Helm, follow the instructions [here](https://helm.sh/docs/intro/install/).

## Choosing a backend

The charts do not assume any particular vendor. Point them at your OTLP endpoint
and supply whatever authentication header that backend expects:

```yaml
otelCollectorEndpoint: https://otlp.example.com:443
otelInsecure: false

# Stored in a Secret and exposed to the collector as ${env:OTEL_API_KEY}
apiKey: "<your-api-key>"

otelExporterHeaders:
  authorization: "Bearer ${env:OTEL_API_KEY}"
```

See the [`k8s-infra` chart README](./charts/k8s-infra/README.md) for the full list of values.

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
