# Wazuh Agent

## Installation

Add the Avisto repository:

```
helm repo add avisto https://avistotelecom.github.io/charts/
```

Search for the version to install:

```
helm search repo -l avisto/wazuh-agent
```

Install the chart:

```
helm install my-wazuh-agent avisto/wazuh-agent --version 4.12.0
```

## Configuration



## Parameters

### Global values

| Name                      | Description                                                                                  | Value                       |
| ------------------------- | -------------------------------------------------------------------------------------------- | --------------------------- |
| `global.imageRegistry`    | Global Docker image registry                                                                 | `rgy.k8s.devops-svc-ag.com` |
| `global.imagePullSecrets` | Global Docker registry secret names as an array                                              | `[]`                        |
| `global.storageClass`     | Global StorageClass for Persistent Volume(s)                                                 | `""`                        |
| `image.registry`          | Wazuh Agent image registry                                                                   | `rgy.k8s.devops-svc-ag.com` |
| `image.pullPolicy`        | Wazuh Agent image pull policy                                                                | `IfNotPresent`              |
| `image.pullSecrets`       | Specify image pull secrets                                                                   | `[]`                        |
| `kubeVersion`             | Override Kubernetes version                                                                  | `""`                        |
| `nameOverride`            | String to partially override common.names.fullname template (will maintain the release name) | `""`                        |
| `fullnameOverride`        | String to fully override common.names.fullname template                                      | `""`                        |
| `clusterDomain`           | Kubernetes Cluster Domain                                                                    | `cluster.local`             |
| `commonLabels`            | Add labels to all the deployed resources                                                     | `{}`                        |
| `commonAnnotations`       | Add annotations to all the deployed resources                                                | `{}`                        |

### Wazuh Agent values

| Name                                                             | Description                                                                                                                                    | Value                |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| `wazuhAgent.name`                                                | Name of the Wazuh Agent                                                                                                                        | `wazuh-agent`        |
| `wazuhAgent.image.registry`                                      | Wazuh Agent image registry                                                                                                                     | `""`                 |
| `wazuhAgent.image.repository`                                    | Wazuh Agent image repository                                                                                                                   | `avisto/wazuh-agent` |
| `wazuhAgent.image.tag`                                           | Wazuh Agent image tag (immutable tags are recommended)                                                                                         | `4.12.0`             |
| `wazuhAgent.image.digest`                                        | Wazuh Agent image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag                                    | `""`                 |
| `wazuhAgent.image.pullPolicy`                                    | Wazuh Agent image pull policy                                                                                                                  | `IfNotPresent`       |
| `wazuhAgent.image.pullSecrets`                                   | Specify image pull secrets                                                                                                                     | `[]`                 |
| `wazuhAgent.configuration.joinManagerMasterHost`                 | Ip address or Domain name of Wazuh server using for restapi                                                                                    | `""`                 |
| `wazuhAgent.configuration.joinManagerWorkerHost`                 | Ip address or Domain name of Wazuh worker for agent connection, if using ALL in One installation the same value as for "joinManagerMasterHost" | `""`                 |
| `wazuhAgent.configuration.joinManagerProtocol`                   | Http or https protocol for Wazuh restapi                                                                                                       | `https`              |
| `wazuhAgent.configuration.joinManagerApiPort`                    | Port where the Wazuh API listened                                                                                                              | `55000`              |
| `wazuhAgent.configuration.joinManagerPort`                       | Port where the Wazuh Server listened                                                                                                           | `1514`               |
| `wazuhAgent.configuration.wazuhGroups`                           | Group(s) name comma separated for auto adding agent                                                                                            | `default`            |
| `wazuhAgent.configuration.joinManagerUser.secretKeyRef.name`     | Name of the Kubernetes secret containing the Wazuh API credentials                                                                             | `wazuh-api-cred`     |
| `wazuhAgent.configuration.joinManagerUser.secretKeyRef.key`      | Name of the key in the Kubernetes secret containing the Wazuh API username                                                                     | `username`           |
| `wazuhAgent.configuration.joinManagerPassword.secretKeyRef.name` | Name of the Kubernetes secret containing the Wazuh API credentials                                                                             | `wazuh-api-cred`     |
| `wazuhAgent.configuration.joinManagerPassword.secretKeyRef.key`  | Name of the key in the Kubernetes secret containing the Wazuh API password                                                                     | `password`           |
| `wazuhAgent.extraEnvVars`                                        | Array with extra environment variables to add to Wazuh Agent nodes                                                                             | `[]`                 |
| `wazuhAgent.extraEnvVarsCM`                                      | Name of existing ConfigMap containing extra env vars for Wazuh Agent nodes                                                                     | `""`                 |
| `wazuhAgent.extraEnvVarsSecret`                                  | Name of existing Secret containing extra env vars for Wazuh Agent nodes                                                                        | `""`                 |
| `wazuhAgent.command`                                             | Override default container command (useful when using custom images)                                                                           | `[]`                 |
| `wazuhAgent.args`                                                | Override default container args (useful when using custom images)                                                                              | `[]`                 |
| `wazuhAgent.livenessProbe.enabled`                               | Enable livenessProbe on Wazuh Agent containers                                                                                                 | `true`               |
| `wazuhAgent.livenessProbe.initialDelaySeconds`                   | Initial delay seconds for livenessProbe                                                                                                        | `40`                 |
| `wazuhAgent.livenessProbe.periodSeconds`                         | Period seconds for livenessProbe                                                                                                               | `10`                 |
| `wazuhAgent.livenessProbe.timeoutSeconds`                        | Timeout seconds for livenessProbe                                                                                                              | `10`                 |
| `wazuhAgent.livenessProbe.failureThreshold`                      | Failure threshold for livenessProbe                                                                                                            | `5`                  |
| `wazuhAgent.readinessProbe.enabled`                              | Enable readinessProbe on Wazuh Agent containers                                                                                                | `true`               |
| `wazuhAgent.readinessProbe.initialDelaySeconds`                  | Initial delay seconds for readinessProbe                                                                                                       | `40`                 |
| `wazuhAgent.readinessProbe.periodSeconds`                        | Period seconds for readinessProbe                                                                                                              | `10`                 |
| `wazuhAgent.readinessProbe.timeoutSeconds`                       | Timeout seconds for readinessProbe                                                                                                             | `10`                 |
| `wazuhAgent.readinessProbe.failureThreshold`                     | Failure threshold for readinessProbe                                                                                                           | `5`                  |
| `wazuhAgent.resources.limits`                                    | The resources limits for the Wazuh Agent containers                                                                                            | `{}`                 |
| `wazuhAgent.resources.requests`                                  | The requested resources for the Wazuh Agent containers                                                                                         | `{}`                 |
| `wazuhAgent.containerSecurityContext.enabled`                    | Enable container security context                                                                                                              | `true`               |
| `wazuhAgent.containerPorts.http`                                 | Wazuh Agent container port for http                                                                                                            | `5000`               |
| `wazuhAgent.labels`                                              | Map of labels to add to the daemonset                                                                                                          | `{}`                 |
| `wazuhAgent.annotations`                                         | Annotations for Wazuh Agent primary pods                                                                                                       | `{}`                 |
| `wazuhAgent.podLabels`                                           | Map of labels to add to the pods                                                                                                               | `{}`                 |
| `wazuhAgent.podAnnotations`                                      | Map of annotations to add to the pods                                                                                                          | `{}`                 |
| `wazuhAgent.updateStrategy`                                      | Wazuh Agent daemonset update strategy                                                                                                          |                      |
| `wazuhAgent.updateStrategy.type`                                 | Wazuh Agent daemonset update strategy type                                                                                                     | `RollingUpdate`      |
| `wazuhAgent.updateStrategy.rollingUpdate`                        | Wazuh Agent daemonset update strategy parameters                                                                                               | `{}`                 |
| `wazuhAgent.extraVolumeMounts`                                   | Optionally specify extra list of additional volumeMounts for the Wazuh Agent container(s)                                                      | `[]`                 |
| `wazuhAgent.extraVolumes`                                        | Optionally specify extra list of additional volumes for the Wazuh Agent pod(s)                                                                 | `[]`                 |
| `wazuhAgent.extraPodSpec`                                        | Optionally specify extra PodSpec for the Wazuh Agent pod(s)                                                                                    | `{}`                 |

## Wazuh agent configuration (ossec.conf)

The wazuh agent needs the /var/ossec/etc/ossec.conf file in order to apply the correct configuration. This file can be mounted to the wazuh agent containers as a configmap.

### Example

The configmap file :

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
    name: wazuh-agent-conf
data:
    ossec.conf: |
        <ossec_config>
        ...
        <ossec_config>
