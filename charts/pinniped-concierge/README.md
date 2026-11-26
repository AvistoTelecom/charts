# Pinniped Concierge

[Pinniped](https://pinniped.dev) Concierge lets users authenticate to a Kubernetes cluster with external credentials (e.g. tokens issued by a Pinniped Supervisor). It exchanges them for cluster credentials, either through the kube-cert-agent (clusters with reachable control-plane nodes) or through its impersonation proxy.

This chart is built from the upstream `install-pinniped-concierge.yaml` release manifests, using the [Bitnami common](https://github.com/bitnami/charts/tree/main/bitnami/common) library.

**Related chart:** [pinniped-supervisor](https://github.com/AvistoTelecom/charts/tree/main/charts/pinniped-supervisor) deploys the Pinniped Supervisor, the usual issuer a Concierge trusts. It is optional: any OIDC issuer works with a JWTAuthenticator.

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

### Handing out a kubeconfig

The kubeconfig from `pinniped get kubeconfig` holds no secret (public CA, client ID and URLs only), so a single file can be shared with every user through a repo or wiki. A few tweaks make it work beyond the admin's machine:

```sh
pinniped get kubeconfig \
  --pinniped-cli-path pinniped \
  --install-hint "Install the pinniped CLI: https://pinniped.dev/docs/howto/install-cli/" \
  > prod.kubeconfig
# Cluster, user and context names are copied from the admin kubeconfig ("<admin-name>-pinniped"):
# rename them to something users recognize (mikefarah/yq v4)
N=prod; yq -i ".clusters[0].name = \"$N\" | .users[0].name = \"$N\" | .contexts[0].name = \"$N\"
  | .contexts[0].context = {\"cluster\": \"$N\", \"user\": \"$N\"} | .current-context = \"$N\"" prod.kubeconfig
```

- `--pinniped-cli-path pinniped`: resolve the CLI from the user's `PATH`. By default the kubeconfig embeds the admin's absolute path (e.g. `/usr/local/bin/pinniped`), which breaks on Homebrew, Windows or `~/bin` installs.
- `--install-hint`: message kubectl shows when the CLI is missing; point it to your own install instructions.
- Login frequency: with a Supervisor, the CLI refreshes the session silently until the Supervisor session expires. When the Concierge trusts an OIDC provider directly, add `offline_access` to `--oidc-scopes` if the provider supports it, otherwise users get a browser login each time the ID token expires.
- `--oidc-skip-browser`: print the login URL instead of opening a browser, for users on SSH sessions or jump hosts.
- The kubeconfig only logs users in. What they can do comes from RBAC bindings on their username or groups, which the chart does not manage (use `extraDeploy` or your usual RBAC tooling).

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
