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

The minimal configuration required to run the wazuh agent is to specify the Wazuh server ip address in the `agent.configuration.joinManagerMasterHost` and `agent.configuration.joinManagerWorkerHost` values as well as wazuh api credentials.

The content of the `values.yaml` should be at least :
```
agent:
  configuration:
    joinManagerMasterHost: <your_wazuh_server_ip>
    joinManagerWorkerHost: <your_wazuh_server_ip>
    username: <your_wazuh_api_username>
    password: <your_wazuh_api_password>
```

### ossec.conf

The wazuh agent needs the /var/ossec/etc/ossec.conf file in order to apply the correct configuration. This file can be mounted to the wazuh agent containers as a configmap.

#### Example

The configmap file :

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
    name: wazuh-agent-conf
data:
    ossec.conf: |
        <ossec_config>
            <YOUR_WAZUH_CONFIGURATION>
        <ossec_config>
```

### Security

Because the role of the wazuh agent is to monitor the activity on the host, the pod needs elevated privileged to access specific files and directories: `/var/run/docker.sock`, `/var/run`, `/dev`, `/sys`, `/proc`, `/etc`, `/boot`, `/usr`, `/lib/modules` and `/var/log`

## Parameters

### Global values

| Name                      | Description                                                                                  | Value           |
| ------------------------- | -------------------------------------------------------------------------------------------- | --------------- |
| `global.imagePullSecrets` | Global Docker registry secret names as an array                                              | `[]`            |
| `global.storageClass`     | Global StorageClass for Persistent Volume(s)                                                 | `""`            |
| `kubeVersion`             | Override Kubernetes version                                                                  | `""`            |
| `nameOverride`            | String to partially override common.names.fullname template (will maintain the release name) | `""`            |
| `fullnameOverride`        | String to fully override common.names.fullname template                                      | `""`            |
| `clusterDomain`           | Kubernetes Cluster Domain                                                                    | `cluster.local` |
| `commonLabels`            | Add labels to all the deployed resources                                                     | `{}`            |
| `commonAnnotations`       | Add annotations to all the deployed resources                                                | `{}`            |

### Wazuh Agent values

| Name                                        | Description                                                                                                                                                  | Value                              |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------- |
| `agent.name`                                | Name of the Wazuh Agent                                                                                                                                      | `wazuh-agent`                      |
| `agent.image.registry`                      | Wazuh Agent image registry                                                                                                                                   | `ghcr.io`                          |
| `agent.image.repository`                    | Wazuh Agent image repository                                                                                                                                 | `avistotelecom/docker-wazuh-agent` |
| `agent.image.tag`                           | Wazuh Agent image tag (immutable tags are recommended)                                                                                                       | `4.12.0`                           |
| `agent.image.digest`                        | Wazuh Agent image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag                                                  | `""`                               |
| `agent.image.pullPolicy`                    | Wazuh Agent image pull policy                                                                                                                                | `IfNotPresent`                     |
| `agent.image.pullSecrets`                   | Specify image pull secrets                                                                                                                                   | `[]`                               |
| `agent.configuration.joinManagerMasterHost` | Ip address or Domain name of Wazuh server using for restapi                                                                                                  | `""`                               |
| `agent.configuration.joinManagerWorkerHost` | Ip address or Domain name of Wazuh worker for agent connection, if using ALL in One installation (single node) the same value as for "joinManagerMasterHost" | `""`                               |
| `agent.configuration.joinManagerProtocol`   | Http or https protocol for Wazuh restapi                                                                                                                     | `https`                            |
| `agent.configuration.joinManagerApiPort`    | Port where the Wazuh API listened                                                                                                                            | `55000`                            |
| `agent.configuration.joinManagerPort`       | Port where the Wazuh Server listened                                                                                                                         | `1514`                             |
| `agent.configuration.wazuhGroups`           | Group(s) name comma separated for auto adding agent                                                                                                          | `default`                          |
| `agent.existingConfigmap`                   | Name of an existing ConfigMap with agent configuration (ossec.conf)                                                                                          | `""`                               |
| `agent.extraEnvVars`                        | Array with extra environment variables to add to Wazuh Agent nodes                                                                                           | `[]`                               |
| `agent.extraEnvVarsCM`                      | Name of existing ConfigMap containing extra env vars for Wazuh Agent nodes                                                                                   | `""`                               |
| `agent.extraEnvVarsSecret`                  | Name of existing Secret containing extra env vars for Wazuh Agent nodes                                                                                      | `""`                               |
| `agent.command`                             | Override default container command (useful when using custom images)                                                                                         | `[]`                               |
| `agent.args`                                | Override default container args (useful when using custom images)                                                                                            | `[]`                               |
| `agent.livenessProbe.enabled`               | Enable livenessProbe on Wazuh Agent containers                                                                                                               | `true`                             |
| `agent.livenessProbe.initialDelaySeconds`   | Initial delay seconds for livenessProbe                                                                                                                      | `40`                               |
| `agent.livenessProbe.periodSeconds`         | Period seconds for livenessProbe                                                                                                                             | `10`                               |
| `agent.livenessProbe.timeoutSeconds`        | Timeout seconds for livenessProbe                                                                                                                            | `10`                               |
| `agent.livenessProbe.failureThreshold`      | Failure threshold for livenessProbe                                                                                                                          | `5`                                |
| `agent.readinessProbe.enabled`              | Enable readinessProbe on Wazuh Agent containers                                                                                                              | `true`                             |
| `agent.readinessProbe.initialDelaySeconds`  | Initial delay seconds for readinessProbe                                                                                                                     | `40`                               |
| `agent.readinessProbe.periodSeconds`        | Period seconds for readinessProbe                                                                                                                            | `10`                               |
| `agent.readinessProbe.timeoutSeconds`       | Timeout seconds for readinessProbe                                                                                                                           | `10`                               |
| `agent.readinessProbe.failureThreshold`     | Failure threshold for readinessProbe                                                                                                                         | `5`                                |
| `agent.resources.limits`                    | The resources limits for the Wazuh Agent containers                                                                                                          | `{}`                               |
| `agent.resources.requests`                  | The requested resources for the Wazuh Agent containers                                                                                                       | `{}`                               |
| `agent.containerSecurityContext.enabled`    | Enable container security context                                                                                                                            | `true`                             |
| `agent.containerPorts.http`                 | Wazuh Agent container port for http                                                                                                                          | `5000`                             |
| `agent.labels`                              | Map of labels to add to the daemonset                                                                                                                        | `{}`                               |
| `agent.annotations`                         | Annotations for Wazuh Agent primary pods                                                                                                                     | `{}`                               |
| `agent.podLabels`                           | Map of labels to add to the pods                                                                                                                             | `{}`                               |
| `agent.podAnnotations`                      | Map of annotations to add to the pods                                                                                                                        | `{}`                               |
| `agent.updateStrategy`                      | Wazuh Agent daemonset update strategy                                                                                                                        |                                    |
| `agent.updateStrategy.type`                 | Wazuh Agent daemonset update strategy type                                                                                                                   | `RollingUpdate`                    |
| `agent.updateStrategy.rollingUpdate`        | Wazuh Agent daemonset update strategy parameters                                                                                                             | `{}`                               |
| `agent.extraVolumeMounts`                   | Optionally specify extra list of additional volumeMounts for the Wazuh Agent container(s)                                                                    | `[]`                               |
| `agent.extraVolumes`                        | Optionally specify extra list of additional volumes for the Wazuh Agent pod(s)                                                                               | `[]`                               |
| `agent.extraPodSpec`                        | Optionally specify extra PodSpec for the Wazuh Agent pod(s)                                                                                                  | `{}`                               |
