
# K8s-Infra

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.139.0](https://img.shields.io/badge/AppVersion-0.139.0-informational?style=flat-square)

Monitoring your Kubernetes cluster is essential for ensuring performance, stability, and reliability. The `k8s-infra` Helm chart provides a comprehensive solution for collecting metrics, logs, and events from your entire Kubernetes environment and exporting them over OTLP to any OpenTelemetry-compatible backend.

### TL;DR

```sh
helm repo add otel-k8s https://prashant-shahi.github.io/otel-k8s
helm repo update
helm install -n platform --create-namespace "my-release" otel-k8s/k8s-infra \
  --set otelCollectorEndpoint=https://otlp.example.com:443
```

### Introduction

The `k8s-infra` chart provides Kubernetes infrastructure observability by deploying OpenTelemetry components and related resources using the [Helm](https://helm.sh) package manager.

It enables collection of metrics, logs, and events from your Kubernetes cluster, making it easier to monitor and troubleshoot your infrastructure with the observability backend of your choice.

The chart is vendor-neutral: point `otelCollectorEndpoint` at any OTLP endpoint and supply whatever authentication headers your backend expects via `otelExporterHeaders`.
### Prerequisites

- Kubernetes 1.16+
- Helm 3.0+

### Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm repo add otel-k8s https://prashant-shahi.github.io/otel-k8s
helm repo update
helm -n platform --create-namespace install "my-release" otel-k8s/k8s-infra
```

#### Pointing the chart at your backend

```yaml
otelCollectorEndpoint: https://otlp.example.com:443
otelInsecure: false

# Stored in a Secret and exposed to the collector as ${env:OTEL_API_KEY}
apiKey: "<your-api-key>"

# Send whatever header your backend authenticates with
otelExporterHeaders:
  authorization: "Bearer ${env:OTEL_API_KEY}"
```

These commands deploy K8s-infra on the Kubernetes cluster in the default configuration.
The [Configuration](#configuration) section lists the parameters that can be configured during installation:

>[!NOTE]
> ### Installing K8s-Infra on Windows
> Follow these steps to configure k8s-infra for Windows environments.
>
> #### Use OpenTelemetry Collector Contrib for Windows
>
> OpenTelemetry provides Windows-compatible [opentelemetry-collector-contrib](https://hub.docker.com/r/otel/opentelemetry-collector-contrib/tags?name=windows) container images which can be used for k8s-infra. You must specify the Windows image tags in your Helm values configuration.
>
> Add the following configuration to your Helm values file:
>
> ```yaml
> otelAgent:
>   image:
>     tag: 0.123.0-windows-2022-amd64
>
> otelDeployment:
>   image:
>     tag: 0.123.0-windows-2022-amd64
> ```
>
> #### Remove Root Path for Host Metrics
>
> The host metrics receiver requires configuring the `root_path` when using the host receiver for Linux in containers. However, Windows deployments do not require this configuration and the k8s-infra installation may fail if included. Remove the path from the `root_path` key under `presets.hostMetrics` in your Helm values:
>
> ```yaml
> presets:
>   hostMetrics:
>     root_path: ""
> ```
>
> After completing these steps, you can proceed with the [standard k8s-infra installation](#installing-the-chart).

> [!NOTE]
> The `kubeletstats` receiver connects to the kubelet API to collect node and container metrics. 
> By default, it uses the node's **`K8S_HOST_IP`** to ensure reliable connectivity in most IPv4 environments, as this avoids DNS resolution issues seen in some providers.
> In clusters running **IPv6** or **dual-stack**, the host IP might resolve to an unreachable address, causing connection errors. 
> In such cases, you can update the endpoint to use **`K8S_NODE_NAME`** instead, which often works better in IPv6 setups. 
> Example configuration: 
> ```yaml
> presets:
>   kubeletMetrics:
>     endpoint: "${env:K8S_NODE_NAME}:10250"
> ```

### Uninstalling the chart

To uninstall/delete the `my-release` resources:

```bash
helm -n platform uninstall "my-release"
```

See the [Helm docs](https://helm.sh/docs/helm/helm_uninstall/) for documentation on the helm uninstall command.

The command above removes all the Kubernetes components associated
with the chart and deletes the release.

Deletion of the StatefulSet doesn't cascade to deleting associated PVCs. To delete them:

```bash
kubectl -n platform delete pvc --selector app.kubernetes.io/instance=my-release
```

Sometimes everything doesn't get properly removed. If that happens try deleting the namespace:

```bash
kubectl delete namespace platform
```
> [!WARNING]
> ### Breaking Changes
> #### Version 1.0.0
>
> **The chart is now vendor-neutral.** All SigNoz-specific naming has been removed.
>
> | Before | After |
> | --- | --- |
> | `signozApiKey` | `apiKey` |
> | `presets.selfTelemetry.signozApiKey` | `presets.selfTelemetry.apiKey` |
> | `presets.logsCollection.blacklist.signozLogs` | `presets.logsCollection.blacklist.selfLogs` |
> | `presets.logsCollection.whitelist.signozLogs` | `presets.logsCollection.whitelist.selfLogs` |
> | `presets.prometheus.annotationsPrefix: signoz.io` | `presets.prometheus.annotationsPrefix: opentelemetry.io` |
> | env `SIGNOZ_API_KEY` | env `OTEL_API_KEY` |
> | env `SIGNOZ_SELF_TELEMETRY_API_KEY` | env `OTEL_SELF_TELEMETRY_API_KEY` |
> | env `SIGNOZ_COMPONENT` | env `OTEL_COMPONENT` |
> | secret key `signoz-apikey` | secret key `otel-apikey` |
> | resource attribute `signoz.component` | resource attribute `otel.component` |
> | Prometheus job `signoz-scraper` | Prometheus job `otel-scraper` |
> | Prometheus labels `signoz_k8s_{name,instance,component}` | `k8s_{name,instance,component}` |
>
> **Exporter headers are no longer hardcoded.** The `signoz-access-token` and
> `signoz-ingestion-key` headers are gone. Set the header your backend expects yourself:
>
> ```yaml
> otelExporterHeaders:
>   authorization: "Bearer ${env:OTEL_API_KEY}"
>
> presets:
>   selfTelemetry:
>     headers:
>       authorization: "Bearer ${env:OTEL_SELF_TELEMETRY_API_KEY}"
> ```
>
> **`selfLogs` means this chart's own pods.** It previously also matched pods of a
> co-installed SigNoz backend. `whitelist.selfLogs` now defaults to `false`,
> where it used to be `true`. `blacklist.selfLogs` still defaults to `true`.
>
> **Pod scrape annotations changed prefix.** Update `signoz.io/scrape`,
> `signoz.io/port` and `signoz.io/path` on your pods to `opentelemetry.io/*`,
> or set `presets.prometheus.annotationsPrefix` back to `signoz.io`.
>
> #### Version 0.16.0
>
> **Default OTLP exporter changed from gRPC to HTTP.**
> - `presets.otlpExporter.enabled` now defaults to `false`
> - `presets.otlphttpExporter.enabled` now defaults to `true`
>
> **Migration:** if you have set a custom `otelCollectorEndpoint`, update it to the OTLP/HTTP endpoint:
> ```yaml
> # Managed OTLP endpoint
> otelCollectorEndpoint: https://otlp.example.com:443
>
> # In-cluster collector
> otelCollectorEndpoint: http://<otel-collector>:4318
> ```
>
> > [!NOTE]
> > OTLP/HTTP works more reliably across load balancers, ingresses, and proxies than gRPC, and is the recommended protocol for exporting telemetry.
> > You can still use gRPC by setting `presets.otlpExporter.enabled: true` and `presets.otlphttpExporter.enabled: false`.
>
> #### Version 0.15.0
> The following changes have been introduced in this version:
> - Upgraded the OpenTelemetry Collector to version `0.139.0`
> - Removed deprecated variables from the OpenTelemetry Collector configuration to ensure compatibility with the latest version
>
> Review your `otelAgent.config` / `otelDeployment.config` overrides against the
> OpenTelemetry Collector `0.139.0` release notes before upgrading.
>
>
> #### Version 0.14.1
>
> **Configuration Migration Required:**
> - `presets.loggingExporter` has been deprecated and must be migrated to `presets.debugExporter`.
>
> This change aligns with OpenTelemetry's deprecation of the [logging exporter](https://github.com/open-telemetry/opentelemetry-collector/tree/v0.110.0/exporter/loggingexporter) in favor of the [debug exporter](https://github.com/open-telemetry/opentelemetry-collector/blob/v0.110.0/exporter/debugexporter/README.md).
>
> **Migration Example:**
>
> Replace this configuration:
> ```yaml
> presets:
>   loggingExporter: 
>     enabled: true
>     verbosity: basic
>     samplingInitial: 2
>     samplingThereafter: 500
> ```
>
> With this configuration:
> ```yaml
> presets:
>   debugExporter: 
>     enabled: true
>     verbosity: basic
>     samplingInitial: 2
>     samplingThereafter: 500
> ```

## Values

<h3>Global Configuration</h3>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="global"><a href="./values.yaml#L3">global</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">cloud: other
clusterDomain: cluster.local
clusterName: ""
deploymentEnvironment: ""
imagePullSecrets: []
imageRegistry: null
storageClass: null</pre>
</div>
            </td>
            <td>Global override values.</td>
        </tr>
        <tr>
            <td id="global--imageRegistry"><a href="./values.yaml#L6">global.imageRegistry</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">null</pre>
</div>
            </td>
            <td>Overrides the Docker registry globally for all images.</td>
        </tr>
        <tr>
            <td id="global--imagePullSecrets"><a href="./values.yaml#L9">global.imagePullSecrets</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Global Image Pull Secrets.</td>
        </tr>
        <tr>
            <td id="global--storageClass"><a href="./values.yaml#L12">global.storageClass</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">null</pre>
</div>
            </td>
            <td>Overrides the storage class for all PVCs with persistence enabled.</td>
        </tr>
        <tr>
            <td id="global--clusterDomain"><a href="./values.yaml#L15">global.clusterDomain</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">cluster.local</pre>
</div>
            </td>
            <td>Kubernetes cluster domain. Used only when components are installed in different namespaces.</td>
        </tr>
        <tr>
            <td id="global--clusterName"><a href="./values.yaml#L18">global.clusterName</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>Kubernetes cluster name. Used to attach to telemetry data via the resource detection processor.</td>
        </tr>
        <tr>
            <td id="global--deploymentEnvironment"><a href="./values.yaml#L21">global.deploymentEnvironment</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>Deployment environment to be attached to telemetry data.</td>
        </tr>
        <tr>
            <td id="global--cloud"><a href="./values.yaml#L24">global.cloud</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">other</pre>
</div>
            </td>
            <td>Kubernetes cluster cloud provider, along with distribution if any (e.g., `aws`, `azure`, `gcp`, `gcp/autogke`, `other`).</td>
        </tr>
    </tbody>
</table>
<h3>General Configuration</h3>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="nameOverride"><a href="./values.yaml#L27">nameOverride</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>K8s infra chart name override.</td>
        </tr>
        <tr>
            <td id="fullnameOverride"><a href="./values.yaml#L30">fullnameOverride</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>K8s infra chart full name override.</td>
        </tr>
        <tr>
            <td id="enabled"><a href="./values.yaml#L33">enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Whether to enable the K8s infra chart.</td>
        </tr>
        <tr>
            <td id="clusterName"><a href="./values.yaml#L36">clusterName</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>Name of the K8s cluster. Used by OtelCollectors to attach in telemetry data.</td>
        </tr>
        <tr>
            <td id="otelCollectorEndpoint"><a href="./values.yaml#L42">otelCollectorEndpoint</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">null</pre>
</div>
            </td>
            <td>OTLP endpoint of the OpenTelemetry backend to export to. Point this at any OTLP-compatible backend, e.g. `https://otlp.example.com:443`. If set to null and the chart is installed as a dependency, it will attempt to autogenerate the endpoint of the in-cluster OpenTelemetry Collector.</td>
        </tr>
        <tr>
            <td id="otelExporterHeaders"><a href="./values.yaml#L47">otelExporterHeaders</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Extra headers sent with every OTLP export request. Values may reference env vars, e.g. `${env:OTEL_API_KEY}` for the key set in `apiKey`. Use this to pass whatever authentication header your backend expects.</td>
        </tr>
        <tr>
            <td id="otelInsecure"><a href="./values.yaml#L53">otelInsecure</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Whether the OTLP endpoint is insecure. Set this to false in case of a secure OTLP endpoint.</td>
        </tr>
        <tr>
            <td id="insecureSkipVerify"><a href="./values.yaml#L56">insecureSkipVerify</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Whether to skip verifying the OTLP endpoint's certificate.</td>
        </tr>
        <tr>
            <td id="namespace"><a href="./values.yaml#L93">namespace</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">null</pre>
</div>
            </td>
            <td>The namespace to install k8s-infra components into.</td>
        </tr>
    </tbody>
</table>
<h3>API Key Configuration</h3>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="apiKey"><a href="./values.yaml#L60">apiKey</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>API key for the OTLP backend, exposed to the collector as `${env:OTEL_API_KEY}`. Reference it from `otelExporterHeaders` using the header name your backend expects.</td>
        </tr>
        <tr>
            <td id="apiKeyExistingSecretName"><a href="./values.yaml#L63">apiKeyExistingSecretName</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>Existing secret name to be used for the API key.</td>
        </tr>
        <tr>
            <td id="apiKeyExistingSecretKey"><a href="./values.yaml#L66">apiKeyExistingSecretKey</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>Existing secret key to be used for the API key.</td>
        </tr>
    </tbody>
</table>
<h3>OTLP Receiver TLS Configuration</h3>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="otelTlsSecrets--enabled"><a href="./values.yaml#L71">otelTlsSecrets.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Whether to enable OpenTelemetry OTLP secrets for secure communication.</td>
        </tr>
        <tr>
            <td id="otelTlsSecrets--path"><a href="./values.yaml#L74">otelTlsSecrets.path</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">/secrets</pre>
</div>
            </td>
            <td>Path for the secrets volume when mounted in the container.</td>
        </tr>
        <tr>
            <td id="otelTlsSecrets--existingSecretName"><a href="./values.yaml#L78">otelTlsSecrets.existingSecretName</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">null</pre>
</div>
            </td>
            <td>Name of an existing secret with TLS certificate, key, and CA to be used. Files in the secret must be named `cert.pem`, `key.pem`, and `ca.pem`.</td>
        </tr>
        <tr>
            <td id="otelTlsSecrets--certificate"><a href="./values.yaml#L81">otelTlsSecrets.certificate</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">|
    <INCLUDE_CERTIFICATE_HERE></pre>
</div>
            </td>
            <td>TLS certificate to be included in the secret.</td>
        </tr>
        <tr>
            <td id="otelTlsSecrets--key"><a href="./values.yaml#L85">otelTlsSecrets.key</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">|
    <INCLUDE_PRIVATE_KEY_HERE></pre>
</div>
            </td>
            <td>TLS private key to be included in the secret.</td>
        </tr>
        <tr>
            <td id="otelTlsSecrets--ca"><a href="./values.yaml#L89">otelTlsSecrets.ca</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>TLS certificate authority (CA) certificate to be included in the secret.</td>
        </tr>
    </tbody>
</table><h3>Presets Configuration</h3>
  <p>Presets to easily set up OtelCollector configurations. For more details, see the README of this chart..</p>
<h4>Debug Exporter Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--debugExporter"><a href="./values.yaml#L101">presets.debugExporter</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: false
samplingInitial: 2
samplingThereafter: 500
verbosity: basic</pre>
</div>
            </td>
            <td>Configuration for the debug exporter, used for debugging telemetry data.</td>
        </tr>
        <tr>
            <td id="presets--debugExporter--enabled"><a href="./values.yaml#L104">presets.debugExporter.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable the debug exporter.</td>
        </tr>
        <tr>
            <td id="presets--debugExporter--verbosity"><a href="./values.yaml#L107">presets.debugExporter.verbosity</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">basic</pre>
</div>
            </td>
            <td>Verbosity of the debug exporter: `basic`, `normal`, or `detailed`.</td>
        </tr>
        <tr>
            <td id="presets--debugExporter--samplingInitial"><a href="./values.yaml#L110">presets.debugExporter.samplingInitial</a></td>
            <td>int</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">2</pre>
</div>
            </td>
            <td>Number of messages initially logged each second.</td>
        </tr>
        <tr>
            <td id="presets--debugExporter--samplingThereafter"><a href="./values.yaml#L113">presets.debugExporter.samplingThereafter</a></td>
            <td>int</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">500</pre>
</div>
            </td>
            <td>Sampling rate after the initial messages are logged.</td>
        </tr>
    </tbody>
</table>
<h4>OTLP Exporter Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--otlpExporter"><a href="./values.yaml#L116">presets.otlpExporter</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: false</pre>
</div>
            </td>
            <td>OTLP Exporter for the OTLP exporter.</td>
        </tr>
        <tr>
            <td id="presets--otlphttpExporter"><a href="./values.yaml#L123">presets.otlphttpExporter</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: true</pre>
</div>
            </td>
            <td>OTLP HTTP Exporter to which data will be sent. Set this to true to enable the OTLP HTTP exporter, which uses the HTTP endpoint instead of the gRPC endpoint.</td>
        </tr>
    </tbody>
</table>
<h3>OpenTelemetry Agent (DaemonSet)</h3>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--selfTelemetry"><a href="./values.yaml#L132">presets.selfTelemetry</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">apiKey: ""
apiKeyExistingSecretKey: ""
apiKeyExistingSecretName: ""
endpoint: ""
headers: {}
insecure: true
insecureSkipVerify: true
logs:
    enabled: false
metrics:
    enabled: false
traces:
    enabled: false</pre>
</div>
            </td>
            <td>Configuration for sending the collector's own telemetry data. By Default, the Collector generates basic metrics about itself and exposes them using the OpenTelemetry Go Prometheus exporter for scraping at http://<otel-collector>:8888/metrics Check out docs for more information: https://opentelemetry.io/docs/collector/internal-telemetry/#otlp-exporter-for-internal-metrics</td>
        </tr>
        <tr>
            <td id="otelAgent--enabled"><a href="./values.yaml#L583">otelAgent.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable the OtelAgent DaemonSet.</td>
        </tr>
        <tr>
            <td id="otelAgent--name"><a href="./values.yaml#L586">otelAgent.name</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">otel-agent</pre>
</div>
            </td>
            <td>Name of the OtelAgent DaemonSet.</td>
        </tr>
        <tr>
            <td id="otelAgent--image"><a href="./values.yaml#L589">otelAgent.image</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">pullPolicy: IfNotPresent
registry: docker.io
repository: otel/opentelemetry-collector-contrib
tag: 0.139.0</pre>
</div>
            </td>
            <td>Image configuration for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--image--registry"><a href="./values.yaml#L592">otelAgent.image.registry</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">docker.io</pre>
</div>
            </td>
            <td>Docker registry for the OtelAgent image.</td>
        </tr>
        <tr>
            <td id="otelAgent--image--repository"><a href="./values.yaml#L595">otelAgent.image.repository</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">otel/opentelemetry-collector-contrib</pre>
</div>
            </td>
            <td>Repository for the OtelAgent image.</td>
        </tr>
        <tr>
            <td id="otelAgent--image--tag"><a href="./values.yaml#L599">otelAgent.image.tag</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">0.139.0</pre>
</div>
            </td>
            <td>Tag for the OtelAgent image. In case of your Host OS is windows, use the `0.123.0-windows-2022-amd64` tag.</td>
        </tr>
        <tr>
            <td id="otelAgent--image--pullPolicy"><a href="./values.yaml#L602">otelAgent.image.pullPolicy</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">IfNotPresent</pre>
</div>
            </td>
            <td>Image pull policy for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--imagePullSecrets"><a href="./values.yaml#L605">otelAgent.imagePullSecrets</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Image Pull Secrets for the OtelAgent. Merged with `global.imagePullSecrets`.</td>
        </tr>
        <tr>
            <td id="otelAgent--command"><a href="./values.yaml#L610">otelAgent.command</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">extraArgs: []
name: /otelcol-contrib</pre>
</div>
            </td>
            <td>Command and arguments for the OtelAgent container.</td>
        </tr>
        <tr>
            <td id="otelAgent--command--name"><a href="./values.yaml#L613">otelAgent.command.name</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">/otelcol-contrib</pre>
</div>
            </td>
            <td>OtelAgent command name.</td>
        </tr>
        <tr>
            <td id="otelAgent--command--extraArgs"><a href="./values.yaml#L616">otelAgent.command.extraArgs</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Extra arguments for the OtelAgent command.</td>
        </tr>
        <tr>
            <td id="otelAgent--configMap"><a href="./values.yaml#L619">otelAgent.configMap</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">create: true</pre>
</div>
            </td>
            <td>ConfigMap configuration for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--configMap--create"><a href="./values.yaml#L622">otelAgent.configMap.create</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Specifies whether a ConfigMap should be created.</td>
        </tr>
        <tr>
            <td id="otelAgent--service"><a href="./values.yaml#L625">otelAgent.service</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotations: {}
internalTrafficPolicy: Local
type: ClusterIP</pre>
</div>
            </td>
            <td>Service configuration for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--service--annotations"><a href="./values.yaml#L628">otelAgent.service.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the OtelAgent service.</td>
        </tr>
        <tr>
            <td id="otelAgent--service--type"><a href="./values.yaml#L631">otelAgent.service.type</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">ClusterIP</pre>
</div>
            </td>
            <td>Service type: `ClusterIP`, `NodePort`, or `LoadBalancer`.</td>
        </tr>
        <tr>
            <td id="otelAgent--service--internalTrafficPolicy"><a href="./values.yaml#L635">otelAgent.service.internalTrafficPolicy</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Local</pre>
</div>
            </td>
            <td>Internal traffic policy: `Local` or `Cluster`. ref: https://kubernetes.io/docs/reference/networking/virtual-ips/#internal-traffic-policy</td>
        </tr>
        <tr>
            <td id="otelAgent--serviceAccount"><a href="./values.yaml#L638">otelAgent.serviceAccount</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotations: {}
create: true
name: null</pre>
</div>
            </td>
            <td>ServiceAccount configuration for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--serviceAccount--create"><a href="./values.yaml#L641">otelAgent.serviceAccount.create</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Specifies whether a ServiceAccount should be created.</td>
        </tr>
        <tr>
            <td id="otelAgent--serviceAccount--annotations"><a href="./values.yaml#L644">otelAgent.serviceAccount.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the ServiceAccount.</td>
        </tr>
        <tr>
            <td id="otelAgent--serviceAccount--name"><a href="./values.yaml#L647">otelAgent.serviceAccount.name</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">null</pre>
</div>
            </td>
            <td>The name of the ServiceAccount to use. A name is generated if not set.</td>
        </tr>
        <tr>
            <td id="otelAgent--annotations"><a href="./values.yaml#L650">otelAgent.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the OtelAgent DaemonSet.</td>
        </tr>
        <tr>
            <td id="otelAgent--podAnnotations"><a href="./values.yaml#L653">otelAgent.podAnnotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the OtelAgent pods.</td>
        </tr>
        <tr>
            <td id="otelAgent--additionalEnvs"><a href="./values.yaml#L675">otelAgent.additionalEnvs</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Additional environment variables for the OtelAgent container. You can specify variables in two ways: 1. Flexible structure for advanced configurations (recommended):    Example:      additionalEnvs:        MY_KEY:          value: my-value        SECRET_KEY:          valueFrom:            secretKeyRef:              name: my-secret              key: my-key 2. Simple key-value pairs (backward-compatible):    Example:      additionalEnvs:        MY_KEY: my-value</td>
        </tr>
        <tr>
            <td id="otelAgent--minReadySeconds"><a href="./values.yaml#L678">otelAgent.minReadySeconds</a></td>
            <td>int</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">5</pre>
</div>
            </td>
            <td>Minimum number of seconds for which a newly created Pod should be ready.</td>
        </tr>
        <tr>
            <td id="otelAgent--updateStrategy"><a href="./values.yaml#L689">otelAgent.updateStrategy</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>DaemonSet update strategy for the OtelAgent. When unset, Kubernetes applies its defaults: type=RollingUpdate, rollingUpdate.maxUnavailable=1, rollingUpdate.maxSurge=0. ref: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#update-strategy Example:   updateStrategy:     type: RollingUpdate     rollingUpdate:       maxUnavailable: 25%       maxSurge: 0</td>
        </tr>
        <tr>
            <td id="otelAgent--clusterRole"><a href="./values.yaml#L693">otelAgent.clusterRole</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please checkout the values.yml for default values</pre>
</div>
            </td>
            <td>ClusterRole configuration for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--clusterRole--create"><a href="./values.yaml#L696">otelAgent.clusterRole.create</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Specifies whether a ClusterRole should be created.</td>
        </tr>
        <tr>
            <td id="otelAgent--clusterRole--annotations"><a href="./values.yaml#L699">otelAgent.clusterRole.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the ClusterRole.</td>
        </tr>
        <tr>
            <td id="otelAgent--clusterRole--name"><a href="./values.yaml#L702">otelAgent.clusterRole.name</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>The name of the ClusterRole to use. A name is generated if not set.</td>
        </tr>
        <tr>
            <td id="otelAgent--clusterRole--rules"><a href="./values.yaml#L707">otelAgent.clusterRole.rules</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please checkout the values.yml for default values</pre>
</div>
            </td>
            <td>RBAC rules for the OtelAgent. ref: https://kubernetes.io/docs/reference/access-authn-authz/rbac/</td>
        </tr>
        <tr>
            <td id="otelAgent--clusterRole--clusterRoleBinding"><a href="./values.yaml#L737">otelAgent.clusterRole.clusterRoleBinding</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotations: {}
name: ""</pre>
</div>
            </td>
            <td>ClusterRoleBinding configuration for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--ports"><a href="./values.yaml#L747">otelAgent.ports</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please checkout the values.yml for default values</pre>
</div>
            </td>
            <td>Port configurations for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--ports--otlp--enabled"><a href="./values.yaml#L752">otelAgent.ports.otlp.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable service port for OTLP gRPC.</td>
        </tr>
        <tr>
            <td id="otelAgent--ports--otlp-http--enabled"><a href="./values.yaml#L767">otelAgent.ports.otlp-http.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable service port for OTLP HTTP.</td>
        </tr>
        <tr>
            <td id="otelAgent--ports--zipkin--enabled"><a href="./values.yaml#L782">otelAgent.ports.zipkin.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable service port for Zipkin.</td>
        </tr>
        <tr>
            <td id="otelAgent--ports--metrics--enabled"><a href="./values.yaml#L797">otelAgent.ports.metrics.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable service port for internal metrics.</td>
        </tr>
        <tr>
            <td id="otelAgent--ports--zpages--enabled"><a href="./values.yaml#L812">otelAgent.ports.zpages.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable service port for ZPages.</td>
        </tr>
        <tr>
            <td id="otelAgent--ports--health-check--enabled"><a href="./values.yaml#L827">otelAgent.ports.health-check.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable service port for health checks.</td>
        </tr>
        <tr>
            <td id="otelAgent--ports--pprof--enabled"><a href="./values.yaml#L842">otelAgent.ports.pprof.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable service port for pprof.</td>
        </tr>
        <tr>
            <td id="otelAgent--hostNetwork"><a href="./values.yaml#L856">otelAgent.hostNetwork</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Host networking requested for this pod. Use the host's network namespace. Please make sure while enabling hostNetwork that the host ports are available as it can lead to port conflicts.</td>
        </tr>
        <tr>
            <td id="otelAgent--livenessProbe"><a href="./values.yaml#L860">otelAgent.livenessProbe</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: true
failureThreshold: 6
initialDelaySeconds: 10
path: /
periodSeconds: 10
port: 13133
successThreshold: 1
timeoutSeconds: 5</pre>
</div>
            </td>
            <td>Configure liveness probe. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command</td>
        </tr>
        <tr>
            <td id="otelAgent--readinessProbe"><a href="./values.yaml#L880">otelAgent.readinessProbe</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: true
failureThreshold: 6
initialDelaySeconds: 10
path: /
periodSeconds: 10
port: 13133
successThreshold: 1
timeoutSeconds: 5</pre>
</div>
            </td>
            <td>Configure readiness probe. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes</td>
        </tr>
        <tr>
            <td id="otelAgent--customLivenessProbe"><a href="./values.yaml#L899">otelAgent.customLivenessProbe</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Custom liveness probe configuration.</td>
        </tr>
        <tr>
            <td id="otelAgent--customReadinessProbe"><a href="./values.yaml#L902">otelAgent.customReadinessProbe</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Custom readiness probe configuration.</td>
        </tr>
        <tr>
            <td id="otelAgent--ingress"><a href="./values.yaml#L905">otelAgent.ingress</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotations: {}
className: ""
enabled: false
hosts:
    - host: otel-agent.domain.com
      paths:
        - path: /
          pathType: ImplementationSpecific
          port: 4317
tls: []</pre>
</div>
            </td>
            <td>Ingress configuration for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--ingress--enabled"><a href="./values.yaml#L908">otelAgent.ingress.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable Ingress for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--ingress--className"><a href="./values.yaml#L911">otelAgent.ingress.className</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>Ingress Class Name to be used.</td>
        </tr>
        <tr>
            <td id="otelAgent--ingress--annotations"><a href="./values.yaml#L914">otelAgent.ingress.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the OtelAgent Ingress.</td>
        </tr>
        <tr>
            <td id="otelAgent--ingress--hosts"><a href="./values.yaml#L922">otelAgent.ingress.hosts</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- host: otel-agent.domain.com
  paths:
    - path: /
      pathType: ImplementationSpecific
      port: 4317</pre>
</div>
            </td>
            <td>OtelAgent Ingress hostnames with their path details.</td>
        </tr>
        <tr>
            <td id="otelAgent--ingress--tls"><a href="./values.yaml#L930">otelAgent.ingress.tls</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>OtelAgent Ingress TLS configuration.</td>
        </tr>
        <tr>
            <td id="otelAgent--resources"><a href="./values.yaml#L937">otelAgent.resources</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">requests:
    cpu: 100m
    memory: 100Mi</pre>
</div>
            </td>
            <td>Configure resource requests and limits for the OtelAgent. ref: http://kubernetes.io/docs/user-guide/compute-resources/</td>
        </tr>
        <tr>
            <td id="otelAgent--priorityClassName"><a href="./values.yaml#L947">otelAgent.priorityClassName</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>OtelAgent Priority Class name.</td>
        </tr>
        <tr>
            <td id="otelAgent--nodeSelector"><a href="./values.yaml#L950">otelAgent.nodeSelector</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Node selector for OtelAgent pod assignment.</td>
        </tr>
        <tr>
            <td id="otelAgent--tolerations"><a href="./values.yaml#L953">otelAgent.tolerations</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- operator: Exists</pre>
</div>
            </td>
            <td>Toleration labels for OtelAgent pod assignment.</td>
        </tr>
        <tr>
            <td id="otelAgent--affinity"><a href="./values.yaml#L957">otelAgent.affinity</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Affinity settings for the OtelAgent pod.</td>
        </tr>
        <tr>
            <td id="otelAgent--podSecurityContext"><a href="./values.yaml#L960">otelAgent.podSecurityContext</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Pod-level security configuration.</td>
        </tr>
        <tr>
            <td id="otelAgent--securityContext"><a href="./values.yaml#L965">otelAgent.securityContext</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Container-level security configuration.</td>
        </tr>
        <tr>
            <td id="otelAgent--config"><a href="./values.yaml#L976">otelAgent.config</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please Checkout the values.yml for default values</pre>
</div>
            </td>
            <td>Base configuration for the OtelAgent Collector.</td>
        </tr>
        <tr>
            <td id="otelAgent--config--processors--batch"><a href="./values.yaml#L991">otelAgent.config.processors.batch</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">send_batch_size: 10000
timeout: 200ms</pre>
</div>
            </td>
            <td>Batch processor config. ref: https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/batchprocessor/README.md</td>
        </tr>
        <tr>
            <td id="otelAgent--extraVolumes"><a href="./values.yaml#L1035">otelAgent.extraVolumes</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Additional volumes for the OtelAgent.</td>
        </tr>
        <tr>
            <td id="otelAgent--extraVolumeMounts"><a href="./values.yaml#L1045">otelAgent.extraVolumeMounts</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Additional volume mounts for the OtelAgent.</td>
        </tr>
    </tbody>
</table>
<h4>Self Telemetry Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--selfTelemetry--endpoint"><a href="./values.yaml#L135">presets.selfTelemetry.endpoint</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>OTLP HTTP endpoint to send own telemetry data to.</td>
        </tr>
        <tr>
            <td id="presets--selfTelemetry--traces--enabled"><a href="./values.yaml#L161">presets.selfTelemetry.traces.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable self-telemetry for traces.</td>
        </tr>
        <tr>
            <td id="presets--selfTelemetry--metrics--enabled"><a href="./values.yaml#L167">presets.selfTelemetry.metrics.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable self-telemetry for metrics.</td>
        </tr>
        <tr>
            <td id="presets--selfTelemetry--logs"><a href="./values.yaml#L170">presets.selfTelemetry.logs</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: false</pre>
</div>
            </td>
            <td>Configuration for self-telemetry logs.</td>
        </tr>
        <tr>
            <td id="presets--selfTelemetry--logs--enabled"><a href="./values.yaml#L173">presets.selfTelemetry.logs.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable self-telemetry for logs.</td>
        </tr>
    </tbody>
</table>
<h4>Logs Collection Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--logsCollection"><a href="./values.yaml#L177">presets.logsCollection</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please check out the values.yml for default values</pre>
</div>
            </td>
            <td>Configuration for collecting logs from pods.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--enabled"><a href="./values.yaml#L180">presets.logsCollection.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable log collection.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--startAt"><a href="./values.yaml#L183">presets.logsCollection.startAt</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">end</pre>
</div>
            </td>
            <td>Where to start reading logs from: `end` or `beginning`.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--includeFilePath"><a href="./values.yaml#L186">presets.logsCollection.includeFilePath</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Include the log file path as an attribute.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--includeFileName"><a href="./values.yaml#L189">presets.logsCollection.includeFileName</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Include the log file name as an attribute.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--include"><a href="./values.yaml#L192">presets.logsCollection.include</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- /var/log/pods/*/*/*.log</pre>
</div>
            </td>
            <td>Include path patterns for log files to be collected. By default, all container logs are collected.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--multiline"><a href="./values.yaml#L197">presets.logsCollection.multiline</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">null</pre>
</div>
            </td>
            <td>Configuration that instructs the file_input operator to split log entries using a pattern other than newlines Please refer to the https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/9f1f674d7af62267f641c0b631d1326815ff80d1/receiver/filelogreceiver/README.md for more details.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--blacklist"><a href="./values.yaml#L203">presets.logsCollection.blacklist</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">additionalExclude: []
containers: []
enabled: true
namespaces:
    - kube-system
pods:
    - hotrod
    - locust
selfLogs: true</pre>
</div>
            </td>
            <td>Exclude certain log files from being collected.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--whitelist"><a href="./values.yaml#L227">presets.logsCollection.whitelist</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">additionalInclude: []
containers: []
enabled: false
namespaces: []
pods: []
selfLogs: false</pre>
</div>
            </td>
            <td>Whitelist certain log files to be collected. If enabled, `include` is ignored.</td>
        </tr>
        <tr>
            <td id="presets--logsCollection--operators"><a href="./values.yaml#L248">presets.logsCollection.operators</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- id: container-parser
  type: container</pre>
</div>
            </td>
            <td>A list of log processing operators.</td>
        </tr>
    </tbody>
</table>
<h4>Host Metrics Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--hostMetrics"><a href="./values.yaml#L254">presets.hostMetrics</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please check out the values.yml for default values</pre>
</div>
            </td>
            <td>Configuration for collecting host-level metrics from nodes.</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--enabled"><a href="./values.yaml#L257">presets.hostMetrics.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable host metrics collection.</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--rootPath"><a href="./values.yaml#L261">presets.hostMetrics.rootPath</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">/hostfs</pre>
</div>
            </td>
            <td>Root path for host metrics collection (Linux only).</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--collectionInterval"><a href="./values.yaml#L264">presets.hostMetrics.collectionInterval</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">30s</pre>
</div>
            </td>
            <td>Frequency at which to scrape host metrics.</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--scrapers"><a href="./values.yaml#L268">presets.hostMetrics.scrapers</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please check out the values.yml for default values</pre>
</div>
            </td>
            <td>Fine-grained control over which host metric scrapers are enabled.</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--scrapers--cpu"><a href="./values.yaml#L271">presets.hostMetrics.scrapers.cpu</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Enable CPU metrics collection.</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--scrapers--load"><a href="./values.yaml#L274">presets.hostMetrics.scrapers.load</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Enable load metrics collection.</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--scrapers--memory"><a href="./values.yaml#L277">presets.hostMetrics.scrapers.memory</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Enable memory metrics collection.</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--scrapers--disk"><a href="./values.yaml#L280">presets.hostMetrics.scrapers.disk</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">exclude:
    devices:
        - ^ram\d+$
        - ^zram\d+$
        - ^loop\d+$
        - ^fd\d+$
        - ^hd[a-z]\d+$
        - ^sd[a-z]\d+$
        - ^vd[a-z]\d+$
        - ^xvd[a-z]\d+$
        - ^nvme\d+n\d+p\d+$
    match_type: regexp</pre>
</div>
            </td>
            <td>Enable disk metrics collection.</td>
        </tr>
        <tr>
            <td id="presets--hostMetrics--scrapers--network"><a href="./values.yaml#L336">presets.hostMetrics.scrapers.network</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">exclude:
    interfaces:
        - ^veth.*$
        - ^docker.*$
        - ^br-.*$
        - ^flannel.*$
        - ^cali.*$
        - ^cbr.*$
        - ^cni.*$
        - ^dummy.*$
        - ^tailscale.*$
        - ^lo$
    match_type: regexp</pre>
</div>
            </td>
            <td>Enable network metrics collection.</td>
        </tr>
    </tbody>
</table>
<h4>Kubelet Metrics Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--kubeletMetrics"><a href="./values.yaml#L353">presets.kubeletMetrics</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please check out the values.yml for default values</pre>
</div>
            </td>
            <td>Configuration for collecting metrics from Kubelet.</td>
        </tr>
        <tr>
            <td id="presets--kubeletMetrics--enabled"><a href="./values.yaml#L356">presets.kubeletMetrics.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable Kubelet metrics collection.</td>
        </tr>
        <tr>
            <td id="presets--kubeletMetrics--collectionInterval"><a href="./values.yaml#L359">presets.kubeletMetrics.collectionInterval</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">30s</pre>
</div>
            </td>
            <td>Frequency at which to scrape Kubelet metrics.</td>
        </tr>
        <tr>
            <td id="presets--kubeletMetrics--authType"><a href="./values.yaml#L362">presets.kubeletMetrics.authType</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">serviceAccount</pre>
</div>
            </td>
            <td>Authentication type to use with Kubelet: `serviceAccount` or `tls`.</td>
        </tr>
        <tr>
            <td id="presets--kubeletMetrics--endpoint"><a href="./values.yaml#L367">presets.kubeletMetrics.endpoint</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">${env:K8S_HOST_IP}:10250</pre>
</div>
            </td>
            <td>Kubelet endpoint. The `kubeletstats` receiver uses `K8S_HOST_IP` by default for IPv4 clusters to avoid DNS resolution issues. On IPv6 or dual-stack clusters, if kubelet scraping fails, switch the endpoint to use `K8S_NODE_NAME` instead.</td>
        </tr>
        <tr>
            <td id="presets--kubeletMetrics--insecureSkipVerify"><a href="./values.yaml#L370">presets.kubeletMetrics.insecureSkipVerify</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Skip verifying Kubelet's certificate.</td>
        </tr>
        <tr>
            <td id="presets--kubeletMetrics--extraMetadataLabels"><a href="./values.yaml#L375">presets.kubeletMetrics.extraMetadataLabels</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- container.id
- k8s.volume.type</pre>
</div>
            </td>
            <td>List of extra metadata labels to collect. For GCP/GKE clusters, extraMetadataLabels may not be available due to kubelet configuration. See the "GKE Autopilot" section of this chart's README for details.</td>
        </tr>
        <tr>
            <td id="presets--kubeletMetrics--metricGroups"><a href="./values.yaml#L380">presets.kubeletMetrics.metricGroups</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- container
- pod
- node
- volume</pre>
</div>
            </td>
            <td>Groups of metrics to collect from Kubelet.</td>
        </tr>
        <tr>
            <td id="presets--kubeletMetrics--metrics"><a href="./values.yaml#L389">presets.kubeletMetrics.metrics</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">container.cpu.usage:
    enabled: true
container.uptime:
    enabled: true
k8s.container.cpu.node.utilization:
    enabled: true
k8s.container.cpu_limit_utilization:
    enabled: true
k8s.container.cpu_request_utilization:
    enabled: true
k8s.container.memory.node.utilization:
    enabled: true
k8s.container.memory_limit_utilization:
    enabled: true
k8s.container.memory_request_utilization:
    enabled: true
k8s.node.cpu.usage:
    enabled: true
k8s.node.uptime:
    enabled: true
k8s.pod.cpu.usage:
    enabled: true
k8s.pod.cpu_limit_utilization:
    enabled: true
k8s.pod.cpu_request_utilization:
    enabled: true
k8s.pod.memory_limit_utilization:
    enabled: true
k8s.pod.memory_request_utilization:
    enabled: true
k8s.pod.uptime:
    enabled: true</pre>
</div>
            </td>
            <td>Fine-grained control over which Kubelet metrics are enabled. Note: In GKE Autopilot clusters ("gcp/autogke"), request and limit metrics are not available to scrape due to Kubelet configuration. See the "GKE Autopilot" section of this chart's README for details.</td>
        </tr>
    </tbody>
</table>
<h4>Kubernetes Attributes Processor Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--kubernetesAttributes"><a href="./values.yaml#L425">presets.kubernetesAttributes</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please check out the values.yml for default values</pre>
</div>
            </td>
            <td>Processor for adding Kubernetes attributes to telemetry data.</td>
        </tr>
        <tr>
            <td id="presets--kubernetesAttributes--enabled"><a href="./values.yaml#L428">presets.kubernetesAttributes.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable the Kubernetes attributes processor.</td>
        </tr>
        <tr>
            <td id="presets--kubernetesAttributes--passthrough"><a href="./values.yaml#L431">presets.kubernetesAttributes.passthrough</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>If true, agents will not make k8s API calls, do discovery, or extract metadata.</td>
        </tr>
        <tr>
            <td id="presets--kubernetesAttributes--filter"><a href="./values.yaml#L434">presets.kubernetesAttributes.filter</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">node_from_env_var: K8S_NODE_NAME</pre>
</div>
            </td>
            <td>Limit agents to query pods based on specific selectors to reduce resource usage.</td>
        </tr>
        <tr>
            <td id="presets--kubernetesAttributes--filter--node_from_env_var"><a href="./values.yaml#L437">presets.kubernetesAttributes.filter.node_from_env_var</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">K8S_NODE_NAME</pre>
</div>
            </td>
            <td>Restrict each agent to query pods on the same node.</td>
        </tr>
        <tr>
            <td id="presets--kubernetesAttributes--podAssociation"><a href="./values.yaml#L440">presets.kubernetesAttributes.podAssociation</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- sources:
    - from: resource_attribute
      name: k8s.pod.ip
- sources:
    - from: resource_attribute
      name: k8s.pod.uid
- sources:
    - from: connection</pre>
</div>
            </td>
            <td>Rules for tagging telemetry with pod metadata.</td>
        </tr>
        <tr>
            <td id="presets--kubernetesAttributes--extractMetadatas"><a href="./values.yaml#L451">presets.kubernetesAttributes.extractMetadatas</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- k8s.namespace.name
- k8s.deployment.name
- k8s.statefulset.name
- k8s.daemonset.name
- k8s.cronjob.name
- k8s.job.name
- k8s.node.name
- k8s.node.uid
- k8s.pod.name
- k8s.pod.uid
- k8s.pod.start_time</pre>
</div>
            </td>
            <td>Pod/namespace metadata to extract from a list of default metadata fields.</td>
        </tr>
        <tr>
            <td id="presets--kubernetesAttributes--extractLabels"><a href="./values.yaml#L465">presets.kubernetesAttributes.extractLabels</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Pod labels to extract as attributes.</td>
        </tr>
        <tr>
            <td id="presets--kubernetesAttributes--extractAnnotations"><a href="./values.yaml#L468">presets.kubernetesAttributes.extractAnnotations</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Pod annotations to extract as attributes.</td>
        </tr>
    </tbody>
</table>
<h4>Cluster Metrics Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--clusterMetrics"><a href="./values.yaml#L472">presets.clusterMetrics</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please check out the values.yml for default values</pre>
</div>
            </td>
            <td>Configuration for collecting cluster-level metrics.</td>
        </tr>
        <tr>
            <td id="presets--clusterMetrics--enabled"><a href="./values.yaml#L475">presets.clusterMetrics.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable cluster metrics collection.</td>
        </tr>
        <tr>
            <td id="presets--clusterMetrics--collectionInterval"><a href="./values.yaml#L478">presets.clusterMetrics.collectionInterval</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">30s</pre>
</div>
            </td>
            <td>Frequency at which to scrape cluster metrics.</td>
        </tr>
        <tr>
            <td id="presets--clusterMetrics--resourceAttributes"><a href="./values.yaml#L481">presets.clusterMetrics.resourceAttributes</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">container.runtime:
    enabled: true
container.runtime.version:
    enabled: true
k8s.container.status.last_terminated_reason:
    enabled: true
k8s.kubelet.version:
    enabled: true
k8s.pod.qos_class:
    enabled: true</pre>
</div>
            </td>
            <td>Resource attributes to report.</td>
        </tr>
        <tr>
            <td id="presets--clusterMetrics--nodeConditionsToReport"><a href="./values.yaml#L494">presets.clusterMetrics.nodeConditionsToReport</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- Ready
- MemoryPressure
- DiskPressure
- PIDPressure
- NetworkUnavailable</pre>
</div>
            </td>
            <td>Node conditions to report as metrics.</td>
        </tr>
        <tr>
            <td id="presets--clusterMetrics--allocatableTypesToReport"><a href="./values.yaml#L502">presets.clusterMetrics.allocatableTypesToReport</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- cpu
- memory</pre>
</div>
            </td>
            <td>Allocatable resource types to report.</td>
        </tr>
        <tr>
            <td id="presets--clusterMetrics--metrics"><a href="./values.yaml#L509">presets.clusterMetrics.metrics</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">k8s.container.status.reason:
    enabled: true
k8s.container.status.state:
    enabled: true
k8s.node.condition:
    enabled: true
k8s.pod.status_reason:
    enabled: true</pre>
</div>
            </td>
            <td>Fine-grained control over which cluster metrics are enabled.</td>
        </tr>
    </tbody>
</table>
<h4>Prometheus Metrics Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--prometheus"><a href="./values.yaml#L526">presets.prometheus</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotationsPrefix: opentelemetry.io
enabled: false
includeContainerName: false
includePodLabel: false
namespaceScoped: false
namespaces: []
scrapeConfigs: []
scrapeInterval: 60s</pre>
</div>
            </td>
            <td>Configuration for scraping Prometheus metrics from pod annotations.</td>
        </tr>
        <tr>
            <td id="presets--prometheus--enabled"><a href="./values.yaml#L529">presets.prometheus.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable Prometheus metrics scraping.</td>
        </tr>
        <tr>
            <td id="presets--prometheus--annotationsPrefix"><a href="./values.yaml#L532">presets.prometheus.annotationsPrefix</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">opentelemetry.io</pre>
</div>
            </td>
            <td>Prefix for the pod annotations used for metrics scraping (e.g., `opentelemetry.io`).</td>
        </tr>
        <tr>
            <td id="presets--prometheus--scrapeInterval"><a href="./values.yaml#L535">presets.prometheus.scrapeInterval</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">60s</pre>
</div>
            </td>
            <td>How often to scrape metrics.</td>
        </tr>
        <tr>
            <td id="presets--prometheus--namespaceScoped"><a href="./values.yaml#L538">presets.prometheus.namespaceScoped</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Only scrape metrics from pods in the same namespace.</td>
        </tr>
        <tr>
            <td id="presets--prometheus--namespaces"><a href="./values.yaml#L541">presets.prometheus.namespaces</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>If set, only scrape metrics from pods in the specified namespaces.</td>
        </tr>
        <tr>
            <td id="presets--prometheus--includePodLabel"><a href="./values.yaml#L544">presets.prometheus.includePodLabel</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Include all pod labels in the metrics (can cause high cardinality).</td>
        </tr>
        <tr>
            <td id="presets--prometheus--includeContainerName"><a href="./values.yaml#L547">presets.prometheus.includeContainerName</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Include container name in metrics (not recommended for multi-container pods).</td>
        </tr>
        <tr>
            <td id="presets--prometheus--scrapeConfigs"><a href="./values.yaml#L550">presets.prometheus.scrapeConfigs</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Custom scraper configs used for metrics scraping</td>
        </tr>
    </tbody>
</table>
<h4>Resource Detection Processor Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--resourceDetection"><a href="./values.yaml#L553">presets.resourceDetection</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: true
envResourceAttributes: ""
override: false
timeout: 2s</pre>
</div>
            </td>
            <td>Processor for detecting resource information from the environment (e.g., cloud provider, k8s).</td>
        </tr>
        <tr>
            <td id="presets--resourceDetection--enabled"><a href="./values.yaml#L556">presets.resourceDetection.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable the resource detection processor.</td>
        </tr>
        <tr>
            <td id="presets--resourceDetection--timeout"><a href="./values.yaml#L559">presets.resourceDetection.timeout</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">2s</pre>
</div>
            </td>
            <td>Timeout for resource detection.</td>
        </tr>
        <tr>
            <td id="presets--resourceDetection--override"><a href="./values.yaml#L562">presets.resourceDetection.override</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Whether to override existing resource attributes.</td>
        </tr>
        <tr>
            <td id="presets--resourceDetection--envResourceAttributes"><a href="./values.yaml#L565">presets.resourceDetection.envResourceAttributes</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>Additional resource attributes from environment variables.</td>
        </tr>
    </tbody>
</table>
<h4>Kubernetes Events Collection Presets</h4>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="presets--k8sEvents"><a href="./values.yaml#L568">presets.k8sEvents</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">authType: serviceAccount
enabled: true
namespaces: []</pre>
</div>
            </td>
            <td>Configuration for collecting Kubernetes events as logs.</td>
        </tr>
        <tr>
            <td id="presets--k8sEvents--enabled"><a href="./values.yaml#L571">presets.k8sEvents.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable Kubernetes events collection.</td>
        </tr>
        <tr>
            <td id="presets--k8sEvents--authType"><a href="./values.yaml#L574">presets.k8sEvents.authType</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">serviceAccount</pre>
</div>
            </td>
            <td>Authentication type: `serviceAccount` or `kubeconfig`.</td>
        </tr>
        <tr>
            <td id="presets--k8sEvents--namespaces"><a href="./values.yaml#L577">presets.k8sEvents.namespaces</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>List of namespaces to watch for events. Empty list means all namespaces.</td>
        </tr>
    </tbody>
</table>
<h3>OpenTelemetry Deployment</h3>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="otelDeployment--enabled"><a href="./values.yaml#L1056">otelDeployment.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--name"><a href="./values.yaml#L1059">otelDeployment.name</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">otel-deployment</pre>
</div>
            </td>
            <td>Name of the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--image"><a href="./values.yaml#L1062">otelDeployment.image</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">pullPolicy: IfNotPresent
registry: docker.io
repository: otel/opentelemetry-collector-contrib
tag: 0.139.0</pre>
</div>
            </td>
            <td>Image configuration for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--image--registry"><a href="./values.yaml#L1065">otelDeployment.image.registry</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">docker.io</pre>
</div>
            </td>
            <td>Docker registry for the OtelDeployment image.</td>
        </tr>
        <tr>
            <td id="otelDeployment--image--repository"><a href="./values.yaml#L1068">otelDeployment.image.repository</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">otel/opentelemetry-collector-contrib</pre>
</div>
            </td>
            <td>Repository for the OtelDeployment image.</td>
        </tr>
        <tr>
            <td id="otelDeployment--image--tag"><a href="./values.yaml#L1072">otelDeployment.image.tag</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">0.139.0</pre>
</div>
            </td>
            <td>Tag for the OtelDeployment image. In case of your Host OS is windows, use the `0.123.0-windows-2022-amd64` tag.</td>
        </tr>
        <tr>
            <td id="otelDeployment--image--pullPolicy"><a href="./values.yaml#L1075">otelDeployment.image.pullPolicy</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">IfNotPresent</pre>
</div>
            </td>
            <td>Image pull policy for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--imagePullSecrets"><a href="./values.yaml#L1078">otelDeployment.imagePullSecrets</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Image Pull Secrets for the OtelDeployment. Merged with `global.imagePullSecrets`.</td>
        </tr>
        <tr>
            <td id="otelDeployment--command"><a href="./values.yaml#L1085">otelDeployment.command</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">extraArgs: []
name: /otelcol-contrib</pre>
</div>
            </td>
            <td>Command and arguments for the OtelDeployment container.</td>
        </tr>
        <tr>
            <td id="otelDeployment--command--name"><a href="./values.yaml#L1088">otelDeployment.command.name</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">/otelcol-contrib</pre>
</div>
            </td>
            <td>OtelDeployment command name.</td>
        </tr>
        <tr>
            <td id="otelDeployment--command--extraArgs"><a href="./values.yaml#L1091">otelDeployment.command.extraArgs</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Extra arguments for the OtelDeployment command.</td>
        </tr>
        <tr>
            <td id="otelDeployment--configMap"><a href="./values.yaml#L1094">otelDeployment.configMap</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">create: true</pre>
</div>
            </td>
            <td>ConfigMap configuration for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--configMap--create"><a href="./values.yaml#L1097">otelDeployment.configMap.create</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Specifies whether a ConfigMap should be created.</td>
        </tr>
        <tr>
            <td id="otelDeployment--service"><a href="./values.yaml#L1100">otelDeployment.service</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotations: {}
type: ClusterIP</pre>
</div>
            </td>
            <td>Service configuration for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--service--annotations"><a href="./values.yaml#L1103">otelDeployment.service.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the OtelDeployment service.</td>
        </tr>
        <tr>
            <td id="otelDeployment--service--type"><a href="./values.yaml#L1106">otelDeployment.service.type</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">ClusterIP</pre>
</div>
            </td>
            <td>Service type.</td>
        </tr>
        <tr>
            <td id="otelDeployment--serviceAccount"><a href="./values.yaml#L1109">otelDeployment.serviceAccount</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotations: {}
create: true
name: null</pre>
</div>
            </td>
            <td>ServiceAccount configuration for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--serviceAccount--create"><a href="./values.yaml#L1112">otelDeployment.serviceAccount.create</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Specifies whether a ServiceAccount should be created.</td>
        </tr>
        <tr>
            <td id="otelDeployment--serviceAccount--annotations"><a href="./values.yaml#L1115">otelDeployment.serviceAccount.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the ServiceAccount.</td>
        </tr>
        <tr>
            <td id="otelDeployment--serviceAccount--name"><a href="./values.yaml#L1118">otelDeployment.serviceAccount.name</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">null</pre>
</div>
            </td>
            <td>The name of the ServiceAccount to use. A name is generated if not set.</td>
        </tr>
        <tr>
            <td id="otelDeployment--annotations"><a href="./values.yaml#L1121">otelDeployment.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--podAnnotations"><a href="./values.yaml#L1124">otelDeployment.podAnnotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the OtelDeployment pods.</td>
        </tr>
        <tr>
            <td id="otelDeployment--additionalEnvs"><a href="./values.yaml#L1131">otelDeployment.additionalEnvs</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Additional environment variables for the OtelDeployment container.</td>
        </tr>
        <tr>
            <td id="otelDeployment--podSecurityContext"><a href="./values.yaml#L1134">otelDeployment.podSecurityContext</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Pod-level security configuration.</td>
        </tr>
        <tr>
            <td id="otelDeployment--securityContext"><a href="./values.yaml#L1139">otelDeployment.securityContext</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Container-level security configuration.</td>
        </tr>
        <tr>
            <td id="otelDeployment--minReadySeconds"><a href="./values.yaml#L1149">otelDeployment.minReadySeconds</a></td>
            <td>int</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">5</pre>
</div>
            </td>
            <td>Minimum number of seconds for which a newly created Pod should be ready.</td>
        </tr>
        <tr>
            <td id="otelDeployment--progressDeadlineSeconds"><a href="./values.yaml#L1152">otelDeployment.progressDeadlineSeconds</a></td>
            <td>int</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">120</pre>
</div>
            </td>
            <td>Seconds to wait for the Deployment to progress before it's considered failed.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ports"><a href="./values.yaml#L1155">otelDeployment.ports</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">health-check:
    containerPort: 13133
    enabled: true
    nodePort: ""
    protocol: TCP
    servicePort: 13133
metrics:
    containerPort: 8888
    enabled: false
    nodePort: ""
    protocol: TCP
    servicePort: 8888
pprof:
    containerPort: 1777
    enabled: false
    nodePort: ""
    protocol: TCP
    servicePort: 1777
zpages:
    containerPort: 55679
    enabled: false
    nodePort: ""
    protocol: TCP
    servicePort: 55679</pre>
</div>
            </td>
            <td>Port configurations for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ports--metrics--enabled"><a href="./values.yaml#L1160">otelDeployment.ports.metrics.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable service port for internal metrics.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ports--zpages--enabled"><a href="./values.yaml#L1173">otelDeployment.ports.zpages.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable service port for ZPages.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ports--health-check--enabled"><a href="./values.yaml#L1186">otelDeployment.ports.health-check.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Enable service port for health checks.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ports--pprof--enabled"><a href="./values.yaml#L1199">otelDeployment.ports.pprof.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable service port for pprof.</td>
        </tr>
        <tr>
            <td id="otelDeployment--livenessProbe"><a href="./values.yaml#L1210">otelDeployment.livenessProbe</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: true
failureThreshold: 6
initialDelaySeconds: 10
path: /
periodSeconds: 10
port: 13133
successThreshold: 1
timeoutSeconds: 5</pre>
</div>
            </td>
            <td>Configure liveness probe.</td>
        </tr>
        <tr>
            <td id="otelDeployment--readinessProbe"><a href="./values.yaml#L1229">otelDeployment.readinessProbe</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">enabled: true
failureThreshold: 6
initialDelaySeconds: 10
path: /
periodSeconds: 10
port: 13133
successThreshold: 1
timeoutSeconds: 5</pre>
</div>
            </td>
            <td>Configure readiness probe.</td>
        </tr>
        <tr>
            <td id="otelDeployment--customLivenessProbe"><a href="./values.yaml#L1248">otelDeployment.customLivenessProbe</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Custom liveness probe configuration.</td>
        </tr>
        <tr>
            <td id="otelDeployment--customReadinessProbe"><a href="./values.yaml#L1251">otelDeployment.customReadinessProbe</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Custom readiness probe configuration.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ingress"><a href="./values.yaml#L1254">otelDeployment.ingress</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotations: {}
className: ""
enabled: false
hosts:
    - host: otel-deployment.domain.com
      paths:
        - path: /
          pathType: ImplementationSpecific
          port: 13133
tls: []</pre>
</div>
            </td>
            <td>Ingress configuration for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ingress--enabled"><a href="./values.yaml#L1257">otelDeployment.ingress.enabled</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">false</pre>
</div>
            </td>
            <td>Enable Ingress for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ingress--className"><a href="./values.yaml#L1260">otelDeployment.ingress.className</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>Ingress Class Name to be used.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ingress--annotations"><a href="./values.yaml#L1263">otelDeployment.ingress.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the OtelDeployment Ingress.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ingress--hosts"><a href="./values.yaml#L1266">otelDeployment.ingress.hosts</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">- host: otel-deployment.domain.com
  paths:
    - path: /
      pathType: ImplementationSpecific
      port: 13133</pre>
</div>
            </td>
            <td>OtelDeployment Ingress hostnames.</td>
        </tr>
        <tr>
            <td id="otelDeployment--ingress--tls"><a href="./values.yaml#L1274">otelDeployment.ingress.tls</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>OtelDeployment Ingress TLS configuration.</td>
        </tr>
        <tr>
            <td id="otelDeployment--resources"><a href="./values.yaml#L1280">otelDeployment.resources</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">requests:
    cpu: 100m
    memory: 100Mi</pre>
</div>
            </td>
            <td>Configure resource requests and limits for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--priorityClassName"><a href="./values.yaml#L1290">otelDeployment.priorityClassName</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>OtelDeployment Priority Class name.</td>
        </tr>
        <tr>
            <td id="otelDeployment--nodeSelector"><a href="./values.yaml#L1293">otelDeployment.nodeSelector</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Node selector for OtelDeployment pod assignment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--tolerations"><a href="./values.yaml#L1296">otelDeployment.tolerations</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Toleration labels for OtelDeployment pod assignment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--affinity"><a href="./values.yaml#L1299">otelDeployment.affinity</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Affinity settings for the OtelDeployment pod.</td>
        </tr>
        <tr>
            <td id="otelDeployment--topologySpreadConstraints"><a href="./values.yaml#L1302">otelDeployment.topologySpreadConstraints</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Describes how OtelDeployment pods ought to spread.</td>
        </tr>
        <tr>
            <td id="otelDeployment--clusterRole"><a href="./values.yaml#L1306">otelDeployment.clusterRole</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please Checkout the values.yml for default values</pre>
</div>
            </td>
            <td>ClusterRole configuration for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--clusterRole--create"><a href="./values.yaml#L1309">otelDeployment.clusterRole.create</a></td>
            <td>bool</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">true</pre>
</div>
            </td>
            <td>Specifies whether a ClusterRole should be created.</td>
        </tr>
        <tr>
            <td id="otelDeployment--clusterRole--annotations"><a href="./values.yaml#L1312">otelDeployment.clusterRole.annotations</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">{}</pre>
</div>
            </td>
            <td>Annotations for the ClusterRole.</td>
        </tr>
        <tr>
            <td id="otelDeployment--clusterRole--name"><a href="./values.yaml#L1315">otelDeployment.clusterRole.name</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">""</pre>
</div>
            </td>
            <td>The name of the ClusterRole to use. A name is generated if not set.</td>
        </tr>
        <tr>
            <td id="otelDeployment--clusterRole--rules"><a href="./values.yaml#L1319">otelDeployment.clusterRole.rules</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please checkout the values.yml for default values</pre>
</div>
            </td>
            <td>RBAC rules for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--clusterRole--clusterRoleBinding"><a href="./values.yaml#L1348">otelDeployment.clusterRole.clusterRoleBinding</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">annotations: {}
name: ""</pre>
</div>
            </td>
            <td>ClusterRoleBinding configuration for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--config"><a href="./values.yaml#L1358">otelDeployment.config</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">Please Checkout the values.yml for default values</pre>
</div>
            </td>
            <td>Base configuration for the OtelDeployment Collector.</td>
        </tr>
        <tr>
            <td id="otelDeployment--config--processors--batch"><a href="./values.yaml#L1365">otelDeployment.config.processors.batch</a></td>
            <td>object</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">send_batch_size: 10000
timeout: 1s</pre>
</div>
            </td>
            <td>Batch processor config.</td>
        </tr>
        <tr>
            <td id="otelDeployment--extraVolumes"><a href="./values.yaml#L1407">otelDeployment.extraVolumes</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Additional volumes for the OtelDeployment.</td>
        </tr>
        <tr>
            <td id="otelDeployment--extraVolumeMounts"><a href="./values.yaml#L1417">otelDeployment.extraVolumeMounts</a></td>
            <td>list</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">[]</pre>
</div>
            </td>
            <td>Additional volume mounts for the OtelDeployment.</td>
        </tr>
    </tbody>
</table>
<h3>OtelDeployment</h3>
<table>
    <thead>
        <th>Key</th>
        <th>Type</th>
        <th>Default</th>
        <th>Description</th>
    </thead>
    <tbody>
        <tr>
            <td id="otelDeployment--strategy"><a href="./values.yaml#L1082">otelDeployment.strategy</a></td>
            <td>string</td>
            <td>
                <div style="max-width: 300px;"><pre lang="yaml">RollingUpdate</pre>
</div>
            </td>
            <td>Deployment strategy to use</td>
        </tr>
    </tbody>
</table>

