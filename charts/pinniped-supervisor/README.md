# Pinniped Supervisor

[Pinniped](https://pinniped.dev) Supervisor is an OIDC issuer that federates upstream identity providers (OIDC, LDAP, Active Directory, GitHub) and issues cluster-scoped credentials consumed by Pinniped Concierges.

This chart is built from the upstream `install-pinniped-supervisor.yaml` release manifests, using the [Bitnami common](https://github.com/bitnami/charts/tree/main/bitnami/common) library.

## Installation

Add repository

```
helm repo add avisto https://avistotelecom.github.io/charts/
```

Install chart (one release per cluster: the CRDs and APIService are cluster-scoped)

```
helm install pinniped-supervisor avisto/pinniped-supervisor --namespace pinniped-supervisor --create-namespace
```

FederationDomains, identity providers and OIDCClients are not managed by this chart: create them with `extraDeploy` or separately.

### Exposing the Supervisor through Gateway API

The Supervisor only serves HTTPS, using the certificate referenced by `FederationDomain.spec.tls.secretName`. With `httpRoute.enabled`, the Gateway terminates TLS and a `BackendTLSPolicy` makes it re-encrypt towards the Supervisor, validating the Supervisor certificate against `httpRoute.hostname`:

```yaml
httpRoute:
  enabled: true
  hostname: pinniped.example.com
backendTLSPolicy:
  validation:
    wellKnownCACertificates: System   # or caCertificateRefs for a private CA
```

### Upgrading

Helm installs the CRDs placed in `crds/` but never upgrades them:

- **Argo CD** applies them on every sync, nothing to do.
- **Flux** upgrades them with `spec.install.crds: CreateReplace` and `spec.upgrade.crds: CreateReplace` on the HelmRelease.
- **Plain Helm / helmfile**: apply them before bumping the chart:

```
helm pull avisto/pinniped-supervisor --version <version> --untar
kubectl apply --server-side -f pinniped-supervisor/crds/
```

The Supervisor patches `spec.caBundle` of its APIService at runtime: GitOps tools should ignore that field.

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

### Pinniped Supervisor parameters

| Name                           | Description                                                                     | Value                                                                     |
| ------------------------------ | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `image.registry`               | Pinniped image registry                                                         | `ghcr.io`                                                                 |
| `image.repository`             | Pinniped image repository                                                       | `vmware/pinniped/pinniped-server`                                         |
| `image.tag`                    | Pinniped image tag                                                              | `v0.48.0`                                                                 |
| `image.digest`                 | Pinniped image digest in the form sha256:aa.... (takes precedence over the tag) | `sha256:c98ed3977081d7e18be6a5176656371621a1deea1a67b5a42f8b152b856ce4c8` |
| `image.pullPolicy`             | Pinniped image pull policy                                                      | `IfNotPresent`                                                            |
| `image.pullSecrets`            | Pinniped image pull secrets                                                     | `[]`                                                                      |
| `replicaCount`                 | Number of Supervisor replicas                                                   | `2`                                                                       |
| `revisionHistoryLimit`         | Number of old ReplicaSets to retain                                             | `10`                                                                      |
| `updateStrategy.type`          | Deployment strategy type                                                        | `RollingUpdate`                                                           |
| `containerPorts.https`         | Port of the OIDC/FederationDomain HTTPS endpoint (Pinniped default)             | `8443`                                                                    |
| `containerPorts.api`           | Port of the aggregated API server (Pinniped default)                            | `10250`                                                                   |
| `config.logUsernamesAndGroups` | Audit log usernames and groups (enabled, disabled)                              | `disabled`                                                                |
| `config.logInternalPaths`      | Audit log internal paths such as /healthz (enabled, disabled)                   | `disabled`                                                                |
| `config.allowedCiphers`        | TLS 1.2 ciphers allowed (empty means Pinniped defaults)                         | `[]`                                                                      |
| `config.extra`                 | Extra keys merged (overwriting) into the generated pinniped.yaml                | `{}`                                                                      |

### Traffic exposure parameters

| Name                          | Description                                                                                                                | Value       |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `service.type`                | Service type                                                                                                               | `ClusterIP` |
| `service.ports.https`         | Service HTTPS port                                                                                                         | `443`       |
| `service.annotations`         | Additional custom annotations for the Service                                                                              | `{}`        |
| `service.labels`              | Additional custom labels for the Service                                                                                   | `{}`        |
| `httpRoute.enabled`           | Enable HTTPRoute (Gateway API) for the Supervisor                                                                          | `false`     |
| `httpRoute.hostname`          | Hostname of the FederationDomain issuer, e.g. pinniped.example.com                                                         | `""`        |
| `httpRoute.annotations`       | Additional annotations for the HTTPRoute                                                                                   | `{}`        |
| `httpRoute.labels`            | Additional labels for the HTTPRoute                                                                                        | `{}`        |
| `httpRoute.parentRefs`        | Gateways the route attaches to                                                                                             | `[]`        |
| `httpRoute.rules`             | HTTPRoute rules. `backendRefs` defaults to the Supervisor Service                                                          | `undefined` |
| `backendTLSPolicy.enabled`    | Create a BackendTLSPolicy so the Gateway talks HTTPS to the Supervisor (needed with httpRoute)                             | `true`      |
| `backendTLSPolicy.validation` | BackendTLSPolicy `spec.validation` (`hostname` defaults to `httpRoute.hostname`). Use `caCertificateRefs` for a private CA | `{}`        |

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
| `priorityClassName`                                 | Pod priority class name                                                                  | `""`             |
| `nodeSelector`                                      | Node labels for pod assignment                                                           | `{}`             |
| `tolerations`                                       | Tolerations for pod assignment                                                           | `[]`             |
| `affinity`                                          | Affinity for pod assignment. When empty, a soft pod anti-affinity on hostname is applied | `{}`             |
| `topologySpreadConstraints`                         | Topology Spread Constraints for pod assignment                                           | `[]`             |
| `extraEnvVars`                                      | Array with extra environment variables                                                   | `[]`             |
| `extraVolumes`                                      | Optionally specify extra list of additional volumes                                      | `[]`             |
| `extraVolumeMounts`                                 | Optionally specify extra list of additional volumeMounts                                 | `[]`             |
| `pdb.create`                                        | Create a PodDisruptionBudget                                                             | `true`           |
| `pdb.maxUnavailable`                                | Max number of pods that can be unavailable                                               | `1`              |
