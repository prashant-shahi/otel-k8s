# otel-k8s

Helm repository for [otel-k8s](https://github.com/prashant-shahi/otel-k8s) —
vendor-neutral Helm charts for collecting Kubernetes telemetry with
OpenTelemetry and exporting it over OTLP to any compatible backend.

## Charts

| Chart | Description |
| --- | --- |
| `k8s-infra` | DaemonSet and Deployment OpenTelemetry Collectors for node/pod metrics, container logs and Kubernetes events. |
| `otel-gateway` | An OpenTelemetry gateway collector that fronts OTLP traffic for a cluster. |

## Usage

```bash
helm repo add otel-k8s https://prashant-shahi.github.io/otel-k8s
helm repo update
helm install my-release otel-k8s/k8s-infra \
  --set otelCollectorEndpoint=https://otlp.example.com:443
```

> [!NOTE]
> No chart versions have been published yet. This index is populated by the
> `release` workflow when a chart version is released from `main`.

See the [repository](https://github.com/prashant-shahi/otel-k8s) for chart
documentation and configuration values.
