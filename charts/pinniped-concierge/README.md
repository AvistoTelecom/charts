# Pinniped Concierge

[Pinniped](https://pinniped.dev) Concierge lets users authenticate to a Kubernetes cluster with external credentials (e.g. tokens issued by a Pinniped Supervisor). It exchanges them for cluster credentials, either through the kube-cert-agent (clusters with reachable control-plane nodes) or through its impersonation proxy.

This chart is built from the upstream `install-pinniped-concierge.yaml` release manifests, using the [Bitnami common](https://github.com/bitnami/charts/tree/main/bitnami/common) library.

## Installation

Add repository

```
helm repo add avisto https://avistotelecom.github.io/charts/
```

Install chart (one release per cluster: the CRDs, APIServices and CredentialIssuer are cluster-scoped)

```
helm install pinniped-concierge avisto/pinniped-concierge --namespace pinniped-concierge --create-namespace
```

The Concierge spawns kube-cert-agent pods with `hostPath` volumes on control-plane nodes: the release namespace must allow the `privileged` Pod Security Standard.

JWTAuthenticators and WebhookAuthenticators are declared in `authenticators.jwt` / `authenticators.webhook` (object name → spec, see the commented examples in `values.yaml`).

### Exposing the impersonation proxy through Gateway API

Instead of the LoadBalancer Service the Concierge creates by default, the impersonation proxy can be exposed with a `TLSRoute`:

```yaml
impersonationProxy:
  mode: enabled
tlsRoute:
  enabled: true
  hostname: concierge.example.com
  parentRefs:
    - name: gateway
      namespace: gateway
      sectionName: tls-passthrough
```

The impersonation proxy authenticates clients with TLS client certificates, so TLS cannot be terminated by the Gateway (an `HTTPRoute` does not work). The parent Gateway needs a passthrough listener, and the cluster needs the `TLSRoute` CRD (standard channel in recent Gateway API releases):

```yaml
- name: tls-passthrough
  hostname: concierge.example.com
  port: 443
  protocol: TLS
  tls:
    mode: Passthrough
  allowedRoutes:
    kinds:
      - kind: TLSRoute
    namespaces:
      from: All
```

The Concierge generates the serving certificate for `concierge.example.com` itself and publishes its CA in the CredentialIssuer status, where `pinniped get kubeconfig` picks it up. Set `impersonationProxy.tls.secretName` to use your own certificate instead.

### Upgrading

Helm installs the CRDs placed in `crds/` but never upgrades them:

- **Argo CD** applies them on every sync, nothing to do.
- **Flux** upgrades them with `spec.install.crds: CreateReplace` and `spec.upgrade.crds: CreateReplace` on the HelmRelease.
- **Plain Helm / helmfile**: apply them before bumping the chart:

```
helm pull avisto/pinniped-concierge --version <version> --untar
kubectl apply --server-side -f pinniped-concierge/crds/
```

The Concierge patches `spec.caBundle` of its APIServices at runtime: GitOps tools should ignore that field.

## Parameters

### Global parameters

| Name                                                  | Description                                                                                                                           | Value   |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `global.imageRegistry`                                | Global Docker image registry                                                                                                          | `""`    |
| `global.imagePullSecrets`                             | Global Docker registry secret names as an array                                                                                       | `[]`    |
| `global.security.allowInsecureImages`                 | Allows skipping image verification                                                                                                    | `false` |
| `global.compatibility.openshift.adaptSecurityContext` | Adapt the securityContext sections of the deployment to make them compatible with Openshift restricted-v2 SCC (auto, force, disabled) | `auto`  |

### Common parameters

| Name                | Description                                       | Value |
| ------------------- | ------------------------------------------------- | ----- |
| `nameOverride`      | String to partially override common.names.name    | `""`  |
| `fullnameOverride`  | String to fully override common.names.fullname    | `""`  |
| `namespaceOverride` | String to fully override common.names.namespace   | `""`  |
| `commonLabels`      | Labels to add to all deployed objects             | `{}`  |
| `commonAnnotations` | Annotations to add to all deployed objects        | `{}`  |
| `extraDeploy`       | Array of extra objects to deploy with the release | `[]`  |

### Pinniped Concierge parameters

| Name                   | Description                                                                     | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `image.registry`       | Pinniped image registry                                                         | `ghcr.io`                                                                 |
| `image.repository`     | Pinniped image repository                                                       | `vmware/pinniped/pinniped-server`                                         |
| `image.tag`            | Pinniped image tag                                                              | `v0.48.0`                                                                 |
| `image.digest`         | Pinniped image digest in the form sha256:aa.... (takes precedence over the tag) | `sha256:c98ed3977081d7e18be6a5176656371621a1deea1a67b5a42f8b152b856ce4c8` |
| `image.pullPolicy`     | Pinniped image pull policy                                                      | `IfNotPresent`                                                            |
| `image.pullSecrets`    | Pinniped image pull secrets (also given to the kube-cert-agent pods)            | `[]`                                                                      |
| `replicaCount`         | Number of Concierge replicas                                                    | `2`                                                                       |
| `revisionHistoryLimit` | Number of old ReplicaSets to retain                                             | `10`                                                                      |
| `updateStrategy.type`  | Deployment strategy type                                                        | `RollingUpdate`                                                           |
| `config`               | Concierge pinniped.yaml settings (upstream defaults)                            | `{}`                                                                      |

### Impersonation proxy parameters

| Name                                  | Description                                                                                                     | Value  |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------ |
| `impersonationProxy.mode`             | Impersonation proxy mode (auto, enabled, disabled). Must be `enabled` when `tlsRoute.enabled=true`              | `auto` |
| `impersonationProxy.externalEndpoint` | Endpoint advertised to clients. Defaults to `tlsRoute.hostname` when the TLSRoute is enabled                    | `""`   |
| `impersonationProxy.service`          | Service created by the Concierge itself. Ignored (forced to `type: None`) when `tlsRoute.enabled=true`          | `{}`   |
| `impersonationProxy.tls`              | Optional TLS settings (`secretName`, `certificateAuthorityData`). When empty the Concierge generates its own CA | `{}`   |

### Exposure parameters

| Name                   | Description                                                                                                        | Value                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------ |
| `tlsRoute.enabled`     | Create a TLSRoute to the impersonation proxy                                                                       | `false`                        |
| `tlsRoute.apiVersion`  | TLSRoute API version (v1 in recent Gateway API standard channel releases, v1alpha2 in older experimental channels) | `gateway.networking.k8s.io/v1` |
| `tlsRoute.hostname`    | Hostname (SNI) of the impersonation proxy, e.g. concierge.example.com                                              | `""`                           |
| `tlsRoute.parentRefs`  | Gateways (and passthrough listener sectionName) the route attaches to                                              | `[]`                           |
| `tlsRoute.labels`      | Additional labels for the TLSRoute                                                                                 | `{}`                           |
| `tlsRoute.annotations` | Additional annotations for the TLSRoute                                                                            | `{}`                           |

### Authenticators

| Name                     | Description                                                                 | Value |
| ------------------------ | --------------------------------------------------------------------------- | ----- |
| `authenticators.jwt`     | JWTAuthenticators, e.g. one trusting a Pinniped Supervisor FederationDomain | `{}`  |
| `authenticators.webhook` | WebhookAuthenticators                                                       | `{}`  |

### Pod parameters

| Name                                                | Description                                                                              | Value            |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------- | ---------------- |
| `resources`                                         | Container resource requests and limits (upstream defaults)                               | `{}`             |
| `podSecurityContext.enabled`                        | Enable pod Security Context                                                              | `true`           |
| `podSecurityContext.fsGroupChangePolicy`            | Set filesystem group change policy                                                       | `Always`         |
| `podSecurityContext.sysctls`                        | Set kernel settings using the sysctl interface                                           | `[]`             |
| `podSecurityContext.supplementalGroups`             | Set filesystem extra groups                                                              | `[]`             |
| `podSecurityContext.runAsUser`                      | User ID for the pod                                                                      | `65532`          |
| `podSecurityContext.runAsGroup`                     | Group ID for the pod                                                                     | `65532`          |
| `containerSecurityContext.enabled`                  | Enable container Security Context                                                        | `true`           |
| `containerSecurityContext.seLinuxOptions`           | Set SELinux options in container                                                         | `{}`             |
| `containerSecurityContext.runAsNonRoot`             | Set runAsNonRoot                                                                         | `true`           |
| `containerSecurityContext.readOnlyRootFilesystem`   | Set readOnlyRootFilesystem                                                               | `true`           |
| `containerSecurityContext.allowPrivilegeEscalation` | Set allowPrivilegeEscalation                                                             | `false`          |
| `containerSecurityContext.capabilities.drop`        | List of capabilities to be dropped                                                       | `["ALL"]`        |
| `containerSecurityContext.seccompProfile.type`      | Set seccomp profile                                                                      | `RuntimeDefault` |
| `livenessProbe.enabled`                             | Enable livenessProbe                                                                     | `true`           |
| `livenessProbe.initialDelaySeconds`                 | Initial delay seconds for livenessProbe                                                  | `2`              |
| `livenessProbe.periodSeconds`                       | Period seconds for livenessProbe                                                         | `10`             |
| `livenessProbe.timeoutSeconds`                      | Timeout seconds for livenessProbe                                                        | `15`             |
| `livenessProbe.failureThreshold`                    | Failure threshold for livenessProbe                                                      | `5`              |
| `readinessProbe.enabled`                            | Enable readinessProbe                                                                    | `true`           |
| `readinessProbe.initialDelaySeconds`                | Initial delay seconds for readinessProbe                                                 | `2`              |
| `readinessProbe.periodSeconds`                      | Period seconds for readinessProbe                                                        | `10`             |
| `readinessProbe.timeoutSeconds`                     | Timeout seconds for readinessProbe                                                       | `3`              |
| `readinessProbe.failureThreshold`                   | Failure threshold for readinessProbe                                                     | `3`              |
| `podLabels`                                         | Extra labels for pods                                                                    | `{}`             |
| `podAnnotations`                                    | Annotations for pods                                                                     | `{}`             |
| `priorityClassName`                                 | Pod priority class name (also used for kube-cert-agent pods)                             | `""`             |
| `nodeSelector`                                      | Node labels for pod assignment                                                           | `{}`             |
| `tolerations`                                       | Tolerations for pod assignment                                                           | `[]`             |
| `affinity`                                          | Affinity for pod assignment. When empty, a soft pod anti-affinity on hostname is applied | `{}`             |
| `topologySpreadConstraints`                         | Topology Spread Constraints for pod assignment                                           | `[]`             |
| `extraEnvVars`                                      | Array with extra environment variables                                                   | `[]`             |
| `extraVolumes`                                      | Optionally specify extra list of additional volumes                                      | `[]`             |
| `extraVolumeMounts`                                 | Optionally specify extra list of additional volumeMounts                                 | `[]`             |
| `pdb.create`                                        | Create a PodDisruptionBudget                                                             | `true`           |
| `pdb.maxUnavailable`                                | Max number of pods that can be unavailable                                               | `1`              |
