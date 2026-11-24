# Pinniped Supervisor

[Pinniped](https://pinniped.dev) Supervisor is an OIDC issuer that federates upstream identity providers (OIDC, LDAP, Active Directory, GitHub) and issues cluster-scoped credentials consumed by Pinniped Concierges.

This chart is built from the upstream `install-pinniped-supervisor.yaml` release manifests, using the [Bitnami common](https://github.com/bitnami/charts/tree/main/bitnami/common) library.

**Related chart:** [pinniped-concierge](https://github.com/AvistoTelecom/charts/tree/main/charts/pinniped-concierge) deploys the Pinniped Concierge, which lets each cluster accept the credentials this Supervisor issues. It is optional: apps can also use the Supervisor directly through OIDCClients.

## Installation

Add repository

```
helm repo add avisto https://avistotelecom.github.io/charts/
```

Install chart (one release per cluster: the CRDs and APIService are cluster-scoped)

```
helm install pinniped-supervisor avisto/pinniped-supervisor --namespace pinniped-supervisor --create-namespace
```

FederationDomains, identity providers and OIDCClients are declared in `federationDomains`, `identityProviders.*` and `oidcClients` (object name → spec, see the commented examples in `values.yaml`). The Secrets they reference are not created by the chart.

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

## Quick start (Supervisor + Concierge)

The usual setup: one Supervisor federating your identity provider, and one Concierge in each cluster that trusts it.

```yaml
# ---- supervisor-values.yaml (pinniped-supervisor chart) ----
# Public endpoint of the Supervisor. The Gateway terminates TLS and re-encrypts
# to the Supervisor (BackendTLSPolicy, enabled by default).
httpRoute:
  enabled: true
  hostname: pinniped.example.com
  parentRefs:
    - name: main-gateway
      namespace: gateway
identityProviders:
  oidc:
    # Upstream IdP. Register https://pinniped.example.com/issuer/callback as redirect URI there.
    # The Secret is yours to create in the release namespace:
    #   type: secrets.pinniped.dev/oidc-client, keys: clientID, clientSecret
    corporate-sso:
      issuer: https://sso.example.com
      authorizationConfig:
        additionalScopes: [offline_access, email, groups]
      claims:
        username: email
        groups: groups
      client:
        secretName: corporate-sso-client
federationDomains:
  # The issuer clusters trust. pinniped-tls holds a certificate for pinniped.example.com
  # (e.g. issued by cert-manager) in the release namespace.
  main:
    issuer: https://pinniped.example.com/issuer
    tls:
      secretName: pinniped-tls
    identityProviders:
      - displayName: corporate-sso
        objectRef:
          apiGroup: idp.supervisor.pinniped.dev
          kind: OIDCIdentityProvider
          name: corporate-sso
---
# ---- concierge-values.yaml (pinniped-concierge chart, in each cluster) ----
authenticators:
  jwt:
    supervisor:
      issuer: https://pinniped.example.com/issuer  # the FederationDomain issuer
      audience: prod-cluster-7f3a9c                 # unique per cluster
```

```sh
helm install pinniped-supervisor avisto/pinniped-supervisor -n pinniped-supervisor --create-namespace -f supervisor-values.yaml

kubectl create namespace pinniped-concierge
kubectl label namespace pinniped-concierge pod-security.kubernetes.io/enforce=privileged
helm install pinniped-concierge avisto/pinniped-concierge -n pinniped-concierge -f concierge-values.yaml

# As cluster admin, generate a kubeconfig to hand out (needs the pinniped CLI)
pinniped get kubeconfig > developer.kubeconfig
# Users log in through their browser on first use. Grant them access with regular
# RBAC bindings on their username (email) or groups.
kubectl --kubeconfig developer.kubeconfig get pods
```

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

| Name                   | Description                                                                     | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `image.registry`       | Pinniped image registry                                                         | `ghcr.io`                                                                 |
| `image.repository`     | Pinniped image repository                                                       | `vmware/pinniped/pinniped-server`                                         |
| `image.tag`            | Pinniped image tag                                                              | `v0.48.0`                                                                 |
| `image.digest`         | Pinniped image digest in the form sha256:aa.... (takes precedence over the tag) | `sha256:c98ed3977081d7e18be6a5176656371621a1deea1a67b5a42f8b152b856ce4c8` |
| `image.pullPolicy`     | Pinniped image pull policy                                                      | `IfNotPresent`                                                            |
| `image.pullSecrets`    | Pinniped image pull secrets                                                     | `[]`                                                                      |
| `replicaCount`         | Number of Supervisor replicas                                                   | `2`                                                                       |
| `revisionHistoryLimit` | Number of old ReplicaSets to retain                                             | `10`                                                                      |
| `updateStrategy.type`  | Deployment strategy type                                                        | `RollingUpdate`                                                           |
| `config`               | Supervisor pinniped.yaml settings (upstream defaults)                           | `{}`                                                                      |

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
| `backendTLSPolicy.enabled`    | Create a BackendTLSPolicy so the Gateway talks HTTPS to the Supervisor (needed with httpRoute)                             | `true`      |
| `backendTLSPolicy.validation` | BackendTLSPolicy `spec.validation` (`hostname` defaults to `httpRoute.hostname`). Use `caCertificateRefs` for a private CA | `{}`        |

### Pinniped resources

| Name                                | Description                                                      | Value |
| ----------------------------------- | ---------------------------------------------------------------- | ----- |
| `federationDomains`                 | FederationDomains                                                | `{}`  |
| `oidcClients`                       | OIDCClients (names must start with `client.oauth.pinniped.dev-`) | `{}`  |
| `identityProviders.oidc`            | OIDCIdentityProviders                                            | `{}`  |
| `identityProviders.ldap`            | LDAPIdentityProviders                                            | `{}`  |
| `identityProviders.activeDirectory` | ActiveDirectoryIdentityProviders                                 | `{}`  |
| `identityProviders.github`          | GitHubIdentityProviders                                          | `{}`  |

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
