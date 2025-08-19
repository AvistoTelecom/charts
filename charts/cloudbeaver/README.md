# Cloudbeaver

Cloudbeaver is a Cloud Database Manager. It is a web server that provides a rich web interface. The server itself is a Java application, and the web part is written in TypeScript and React.
It is free to use and open-source (licensed under [Apache 2](https://github.com/dbeaver/cloudbeaver/blob/devel/LICENSE) license).

## Installation

By default this chart deploys the CE version of Cloudbeaver using the H2 database.

Add repository

```
helm repo add avisto https://avistotelecom.github.io/charts/
```

Install chart

```
helm install my-cloudbeaver avisto/cloudbeaver
```

## Parameters

### Global parameters

| Name                                  | Description                                     | Value   |
| ------------------------------------- | ----------------------------------------------- | ------- |
| `global.imageRegistry`                | Global Docker image registry                    | `""`    |
| `global.imagePullSecrets`             | Global Docker registry secret names as an array | `[]`    |
| `global.security.allowInsecureImages` | Allows skipping image verification              | `false` |

### Common parameters

| Name                | Description                                                                                  | Value           |
| ------------------- | -------------------------------------------------------------------------------------------- | --------------- |
| `nameOverride`      | String to partially override common.names.fullname template (will maintain the release name) | `""`            |
| `fullnameOverride`  | String to fully override common.names.fullname template                                      | `""`            |
| `namespaceOverride` | String to fully override common.names.namespace                                              | `""`            |
| `clusterDomain`     | Kubernetes Cluster Domain                                                                    | `cluster.local` |
| `commonLabels`      | Labels to add to all deployed objects                                                        | `{}`            |
| `commonAnnotations` | Annotations to add to all deployed objects                                                   | `{}`            |
| `extraDeploy`       | Array of extra objects to deploy with the release (evaluated as a template).                 | `[]`            |
| `kubeVersion`       | Force target Kubernetes version (using Helm capabilities if not set)                         | `""`            |

### Cloudbeaver parameters

| Name                                                | Description                                                                                                       | Value                 |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | --------------------- |
| `image.registry`                                    | Cloudbeaver image registry                                                                                        | `docker.io`           |
| `image.repository`                                  | Cloudbeaver image repository                                                                                      | `dbeaver/cloudbeaver` |
| `image.tag`                                         | Cloudbeaver Image tag (immutable tags are recommended)                                                            | `25.1.5`              |
| `image.digest`                                      | Cloudbeaver image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag       | `""`                  |
| `image.pullPolicy`                                  | Cloudbeaver image pull policy                                                                                     | `IfNotPresent`        |
| `image.pullSecrets`                                 | Cloudbeaver image pull secrets                                                                                    | `[]`                  |
| `revisionHistoryLimit`                              | sets number of replicaset to keep in k8s                                                                          | `10`                  |
| `automountServiceAccountToken`                      | Mount Service Account token in pod                                                                                | `false`               |
| `hostAliases`                                       | Deployment pod host aliases                                                                                       | `[]`                  |
| `updateStrategy`                                    | update strategy type                                                                                              |                       |
| `updateStrategy.type`                               | defaults to Recreate because of ReadWriteOnce PVC AccessMode                                                      | `Recreate`            |
| `command`                                           | Override cloudbeaver default command                                                                              | `[]`                  |
| `args`                                              | Override cloudbeaver default args                                                                                 | `[]`                  |
| `livenessProbe.enabled`                             | Enable livenessProbe on cloudbeaver server containers                                                             | `true`                |
| `livenessProbe.initialDelaySeconds`                 | Initial delay seconds for livenessProbe                                                                           | `60`                  |
| `livenessProbe.periodSeconds`                       | Period seconds for livenessProbe                                                                                  | `5`                   |
| `livenessProbe.timeoutSeconds`                      | Timeout seconds for livenessProbe                                                                                 | `1`                   |
| `livenessProbe.failureThreshold`                    | Failure threshold for livenessProbe                                                                               | `5`                   |
| `readinessProbe.enabled`                            | Enable readinessProbe on cloudbeaver server containers                                                            | `true`                |
| `readinessProbe.initialDelaySeconds`                | Initial delay seconds for readinessProbe                                                                          | `5`                   |
| `readinessProbe.periodSeconds`                      | Period seconds for readinessProbe                                                                                 | `5`                   |
| `readinessProbe.timeoutSeconds`                     | Timeout seconds for readinessProbe                                                                                | `1`                   |
| `readinessProbe.failureThreshold`                   | Failure threshold for readinessProbe                                                                              | `5`                   |
| `initContainers`                                    | Attach additional init containers to the pod (evaluated as a template)                                            | `[]`                  |
| `dnsPolicy`                                         | Specifies the DNS policy for the cloudbeaver deployment                                                           | `""`                  |
| `dnsConfig`                                         | allows users more control on the DNS settings for a Pod. Required if `dnsPolicy` is set to `None`                 | `{}`                  |
| `sidecars`                                          | Attach additional containers to the pod (evaluated as a template)                                                 | `[]`                  |
| `containerPorts.http`                               | HTTP Container port                                                                                               | `8978`                |
| `extraEnvVars`                                      | An array to add extra env vars                                                                                    | `[]`                  |
| `extraEnvVarsCM`                                    | ConfigMap containing extra env vars                                                                               | `""`                  |
| `extraEnvVarsSecret`                                | Secret containing extra env vars (in case of sensitive data)                                                      | `""`                  |
| `lifecycleHooks`                                    | Override default etcd container hooks                                                                             | `{}`                  |
| `schedulerName`                                     | Alternative scheduler                                                                                             | `""`                  |
| `topologySpreadConstraints`                         | Topology Spread Constraints for pod assignment                                                                    | `[]`                  |
| `affinity`                                          | Affinity for pod assignment                                                                                       | `{}`                  |
| `nodeSelector`                                      | Node labels for pod assignment                                                                                    | `{}`                  |
| `tolerations`                                       | Tolerations for pod assignment                                                                                    | `[]`                  |
| `podAnnotations`                                    | Additional annotations to apply to the pod.                                                                       | `{}`                  |
| `podLabels`                                         | Additional labels to be added to pods                                                                             | `{}`                  |
| `priorityClassName`                                 | priorityClassName                                                                                                 | `""`                  |
| `secretAnnotations`                                 | Additional annotations to apply to the secret                                                                     | `{}`                  |
| `service.enabled`                                   | Whether to create Service resource or not                                                                         | `true`                |
| `service.type`                                      | Kubernetes Service type                                                                                           | `ClusterIP`           |
| `service.ports.http`                                | Cloudbeaver client port                                                                                           | `8978`                |
| `service.nodePorts.http`                            | Port to bind to for NodePort service type (client port)                                                           | `""`                  |
| `service.clusterIP`                                 | IP address to assign to service                                                                                   | `""`                  |
| `service.externalIPs`                               | Service external IP addresses                                                                                     | `[]`                  |
| `service.externalName`                              | Service external name                                                                                             | `""`                  |
| `service.loadBalancerIP`                            | IP address to assign to load balancer (if supported)                                                              | `""`                  |
| `service.loadBalancerSourceRanges`                  | List of IP CIDRs allowed access to load balancer (if supported)                                                   | `[]`                  |
| `service.externalTrafficPolicy`                     | Enable client source IP preservation                                                                              | `Cluster`             |
| `service.extraPorts`                                | Extra ports to expose in the service (normally used with the `sidecar` value)                                     | `[]`                  |
| `service.annotations`                               | Annotations to add to service                                                                                     | `{}`                  |
| `service.labels`                                    | Provide any additional labels which may be required.                                                              | `{}`                  |
| `service.sessionAffinity`                           | Session Affinity for Kubernetes service, can be "None" or "ClientIP"                                              | `None`                |
| `service.sessionAffinityConfig`                     | Additional settings for the sessionAffinity                                                                       | `{}`                  |
| `containerSecurityContext.enabled`                  | Enabled Apache Server containers' Security Context                                                                | `true`                |
| `containerSecurityContext.seLinuxOptions`           | Set SELinux options in container                                                                                  | `{}`                  |
| `containerSecurityContext.runAsUser`                | Set Cloudbeaver containers' Security Context runAsUser                                                            | `8978`                |
| `containerSecurityContext.runAsGroup`               | Set Cloudbeaver containers' Security Context runAsGroup                                                           | `8978`                |
| `containerSecurityContext.runAsNonRoot`             | Set Cloudbeaver container's Security Context runAsNonRoot                                                         | `true`                |
| `containerSecurityContext.privileged`               | Set primary container's Security Context privileged                                                               | `false`               |
| `containerSecurityContext.allowPrivilegeEscalation` | Set primary container's Security Context allowPrivilegeEscalation                                                 | `false`               |
| `containerSecurityContext.capabilities.drop`        | List of capabilities to be dropped                                                                                | `["ALL"]`             |
| `containerSecurityContext.seccompProfile.type`      | Set container's Security Context seccomp profile                                                                  | `RuntimeDefault`      |
| `podSecurityContext.enabled`                        | Enable pod security context                                                                                       | `true`                |
| `podSecurityContext.fsGroupChangePolicy`            | Set filesystem group change policy                                                                                | `Always`              |
| `podSecurityContext.sysctls`                        | Set kernel settings using the sysctl interface                                                                    | `[]`                  |
| `podSecurityContext.supplementalGroups`             | Set filesystem extra groups                                                                                       | `[]`                  |
| `podSecurityContext.fsGroup`                        | Group ID for the container                                                                                        | `8978`                |
| `resources`                                         | Set container requests and limits for different resources like CPU or memory (essential for production workloads) | `{}`                  |
| `extraVolumes`                                      | A list of volumes to be added to the pod                                                                          | `[]`                  |
| `extraVolumeMounts`                                 | A list of volume mounts to be added to the pod                                                                    | `[]`                  |

### Cloudbeaver persistence parameters

| Name                                    | Description                                                                                                                      | Value                        |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| `persistence.enabled`                   | Enable cloudbeaver data persistence using PVC. If false, use emptyDir                                                            | `true`                       |
| `persistence.storageClass`              | PVC Storage Class for cloudbeaver data volume                                                                                    | `""`                         |
| `persistence.mountPath`                 | Data volume mount path                                                                                                           | `/opt/cloudbeaver/workspace` |
| `persistence.accessModes`               | PVC Access Modes for cloudbeaver data volume                                                                                     | `["ReadWriteOnce"]`          |
| `persistence.size`                      | PVC Storage Request for cloudbeaver data volume                                                                                  | `5Gi`                        |
| `persistence.annotations`               | Annotations for the PVC                                                                                                          | `{}`                         |
| `persistence.existingClaim`             | Name of an existing PVC to use                                                                                                   | `""`                         |
| `persistence.selector`                  | Selector to match an existing Persistent Volume for cloudbeaver data PVC                                                         | `{}`                         |
| `persistence.dataSource`                | Custom PVC data source                                                                                                           | `{}`                         |
| `networkPolicy.enabled`                 | Specifies whether a NetworkPolicy should be created                                                                              | `false`                      |
| `networkPolicy.allowExternal`           | Don't require server label for connections                                                                                       | `false`                      |
| `networkPolicy.allowExternalEgress`     | Allow the pod to access any range of port and all destinations.                                                                  | `true`                       |
| `networkPolicy.kubeAPIServerPorts`      | List of possible endpoints to kube-apiserver (limit to your cluster settings to increase security)                               | `[]`                         |
| `networkPolicy.extraIngress`            | Add extra ingress rules to the NetworkPolicy                                                                                     | `[]`                         |
| `networkPolicy.extraEgress`             | Add extra ingress rules to the NetworkPolicy                                                                                     | `[]`                         |
| `networkPolicy.ingressNSMatchLabels`    | Labels to match to allow traffic from other namespaces                                                                           | `{}`                         |
| `networkPolicy.ingressNSPodMatchLabels` | Pod labels to match to allow traffic from other namespaces                                                                       | `{}`                         |
| `ingress.enabled`                       | Enable ingress record generation for Cloudbeaver                                                                                 | `false`                      |
| `ingress.ingressClassName`              | IngressClass that will be be used to implement the Ingress (Kubernetes 1.18+)                                                    | `""`                         |
| `ingress.pathType`                      | Ingress path type                                                                                                                | `ImplementationSpecific`     |
| `ingress.apiVersion`                    | Force Ingress API version (automatically detected if not set)                                                                    | `""`                         |
| `ingress.controller`                    | The ingress controller type. Currently supports `default` and `gce`                                                              | `default`                    |
| `ingress.hostname`                      | Default host for the ingress record (evaluated as template)                                                                      | `cloudbeaver.local`          |
| `ingress.hostnameStrict`                | Disables dynamically resolving the hostname from request headers.                                                                | `false`                      |
| `ingress.path`                          | Default path for the ingress record (evaluated as template)                                                                      | `""`                         |
| `ingress.servicePort`                   | Backend service port to use                                                                                                      | `http`                       |
| `ingress.annotations`                   | Additional annotations for the Ingress resource. To enable certificate autogeneration, place here your cert-manager annotations. | `{}`                         |
| `ingress.labels`                        | Additional labels for the Ingress resource.                                                                                      | `{}`                         |
| `ingress.tls`                           | Enable TLS configuration for the host defined at `ingress.hostname` parameter                                                    | `false`                      |
| `ingress.selfSigned`                    | Create a TLS secret for this ingress record using self-signed certificates generated by Helm                                     | `false`                      |
| `ingress.extraHosts`                    | An array with additional hostname(s) to be covered with the ingress record                                                       | `[]`                         |
| `ingress.extraPaths`                    | Any additional arbitrary paths that may need to be added to the ingress under the main host.                                     | `[]`                         |
| `ingress.extraTls`                      | The tls configuration for additional hostnames to be covered with this ingress record.                                           | `[]`                         |
| `ingress.secrets`                       | If you're providing your own certificates, please use this to add the certificates as secrets                                    | `[]`                         |
| `ingress.extraRules`                    | Additional rules to be covered with this ingress record                                                                          | `[]`                         |
