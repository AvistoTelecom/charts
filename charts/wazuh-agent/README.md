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

The minimal configuration required to run the wazuh agent is to specify the Wazuh server ip address in the `agent.configuration.joinManagerMasterHost` value as well as wazuh api credentials.

The content of the `values.yaml` should be at least :

```yaml
agent:
  configuration:
    joinManagerMasterHost: <your_wazuh_server_ip>
    username: <your_wazuh_api_username>
    password: <your_wazuh_api_password>
```

### ossec.conf

The wazuh agent needs the `/var/ossec/etc/ossec.conf` file in order to apply the correct configuration. By default, this file is mounted to the wazuh agent containers as a configmap.

#### Overriding the configuration

It is possible to override some parts of the agent configuration using some parameters in the values.yaml.
For example the following configuration override syscollector, syscheck and add further configuration to enable docker events gathering :

```yaml
agent:
  configuration:
    syscollector: |
      <wodle name="syscollector">
        <disabled>no</disabled>
        <interval>6h</interval>
        <scan_on_start>yes</scan_on_start>
        <hardware>yes</hardware>
        <os>yes</os>
        <network>no</network>
        <packages>yes</packages>
        <ports all="no">yes</ports>
        <processes>yes</processes>
        <!-- Database synchronization settings -->
        <synchronization>
          <max_eps>10</max_eps>
        </synchronization>
      </wodle>
    syscheck: |
      <syscheck>
        <disabled>yes</disabled>
      </syscheck>
    additionalconfig: |
      <wodle name="docker-listener">
        <disabled>no</disabled>
      </wodle>
```

#### Using your own configmap

You can use your own configmap to replace the configuration provided by default with this helm chart.
The configmap must respect the following structure :

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
    name: wazuh-custom-configmap
data:
  ossec.conf: |
    <ossec_config>
      <client>
        <server>
          <address><WAZUH_SERVER_IP></address>
          <port><WAZUH_SERVER_PORT></port>
          <protocol>tcp</protocol>
        </server>
        <config-profile>debian, debian12</config-profile>
        <notify_time>10</notify_time>
        <time-reconnect>60</time-reconnect>
        <auto_restart>yes</auto_restart>
        <crypto_method>aes</crypto_method>
      </client>

      <rootcheck>
        <disabled>no</disabled>
        <check_files>yes</check_files>
        <check_trojans>yes</check_trojans>
        <check_dev>yes</check_dev>
        <check_sys>yes</check_sys>
        <check_pids>yes</check_pids>
        <check_ports>yes</check_ports>
        <check_if>yes</check_if>
        <!-- Frequency that rootcheck is executed - every 12 hours -->
        <frequency>43200</frequency>
        <rootkit_files>etc/shared/rootkit_files.txt</rootkit_files>
        <rootkit_trojans>etc/shared/rootkit_trojans.txt</rootkit_trojans>
        <skip_nfs>yes</skip_nfs>
        <ignore>/var/lib/containerd</ignore>
        <ignore>/var/lib/docker/overlay2</ignore>
      </rootcheck>

      <REST_OF_THE_CONFIG>
      ...

    <ossec_config>
```

Replace WAZUH_SERVER_IP and WAZUH_SERVER_PORT with the values of your Wazuh server.
Also, the value of `agent.existingConfigmap` must be set to `wazuh-custom-configmap` in the `values.yaml` file.

### Security

Because the role of the wazuh agent is to monitor the activity on the host, the pod needs elevated privileged to access specific files and directories: `/var/run/docker.sock`, `/var/run`, `/dev`, `/sys`, `/proc`, `/etc`, `/boot`, `/usr`, `/lib/modules` and `/var/log`

## Parameters

### Global values

| Name                      | Description                                                                                  | Value           |
| ------------------------- | -------------------------------------------------------------------------------------------- | --------------- |
| `global.imagePullSecrets` | Global Docker registry secret names as an array                                              | `[]`            |
| `kubeVersion`             | Override Kubernetes version                                                                  | `""`            |
| `nameOverride`            | String to partially override common.names.fullname template (will maintain the release name) | `""`            |
| `fullnameOverride`        | String to fully override common.names.fullname template                                      | `""`            |
| `clusterDomain`           | Kubernetes Cluster Domain                                                                    | `cluster.local` |
| `commonLabels`            | Add labels to all the deployed resources                                                     | `{}`            |
| `commonAnnotations`       | Add annotations to all the deployed resources                                                | `{}`            |

### Wazuh Agent values

| Name                                        | Description                                                                                                                                                   | Value                              |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `agent.name`                                | Name of the Wazuh Agent                                                                                                                                       | `wazuh-agent`                      |
| `agent.image.registry`                      | Wazuh Agent image registry                                                                                                                                    | `ghcr.io`                          |
| `agent.image.repository`                    | Wazuh Agent image repository                                                                                                                                  | `avistotelecom/docker-wazuh-agent` |
| `agent.image.tag`                           | Wazuh Agent image tag (immutable tags are recommended)                                                                                                        | `4.12.0`                           |
| `agent.image.digest`                        | Wazuh Agent image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag                                                   | `""`                               |
| `agent.image.pullPolicy`                    | Wazuh Agent image pull policy                                                                                                                                 | `IfNotPresent`                     |
| `agent.image.pullSecrets`                   | Specify image pull secrets                                                                                                                                    | `[]`                               |
| `agent.configuration.joinManagerMasterHost` | Ip address or Domain name of Wazuh server using for restapi                                                                                                   | `""`                               |
| `agent.configuration.joinManagerProtocol`   | Http or https protocol for Wazuh restapi                                                                                                                      | `https`                            |
| `agent.configuration.joinManagerApiPort`    | Port where the Wazuh API listened                                                                                                                             | `55000`                            |
| `agent.configuration.joinManagerPort`       | Port where the Wazuh Server listened                                                                                                                          | `1514`                             |
| `agent.configuration.username`              | Username of the Wazuh server API                                                                                                                              | `""`                               |
| `agent.configuration.password`              | Password of the Wazuh server API                                                                                                                              | `""`                               |
| `agent.configuration.wazuhGroups`           | Group(s) name comma separated for auto adding agent                                                                                                           | `default`                          |
| `agent.configuration.configProfile`         | Config profile name comma separated                                                                                                                           | `debian, debian12`                 |
| `agent.configuration.rootcheck`             | Rootcheck configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Must start with \<rootcheck\> and end with \</rootcheck\>                   | `""`                               |
| `agent.configuration.ciscat`                | Cis-cat configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Must start with \<wodle name="cis-cat"\> and end with \</wodle\>              | `""`                               |
| `agent.configuration.osquery`               | Osquery configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Must start with \<wodle name="osquery"\> and end with \</wodle\>              | `""`                               |
| `agent.configuration.syscollector`          | Syscollector configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Must start with \<wodle name="syscollector"\> and end with \</wodle\>    | `""`                               |
| `agent.configuration.sca`                   | Sca configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Must start with \<sca\> and end with \</sca\>                                     | `""`                               |
| `agent.configuration.syscheck`              | Syscheck configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Must start with \<syscheck\> and end with \</syscheck\>                      | `""`                               |
| `agent.configuration.loganalysis`           | Log analysis configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Could contain multiple \<localfile\>\</localfile\> blocks                | `""`                               |
| `agent.configuration.activeresponse`        | Active response configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Must start with \<active-response\> and end with \</active-response\> | `""`                               |
| `agent.configuration.logformat`             | Log format configuration of the Wazuh agent (ossec.conf) formatted as YAML block text. Must start with \<logging\> and end with \</logging\>                      | `""`                               |
| `agent.configuration.additionalconfig`      | Additional configuration of the Wazuh agent (ossec.conf) which is not provided by the previous parameters and formatted as YAML block text.                   | `""`                               |
| `agent.existingConfigmap`                   | Name of an existing ConfigMap with agent configuration (ossec.conf)                                                                                           | `""`                               |
| `agent.extraEnvVars`                        | Array with extra environment variables to add to Wazuh Agent nodes                                                                                            | `[]`                               |
| `agent.extraEnvVarsCM`                      | Name of existing ConfigMap containing extra env vars for Wazuh Agent nodes                                                                                    | `""`                               |
| `agent.extraEnvVarsSecret`                  | Name of existing Secret containing extra env vars for Wazuh Agent nodes                                                                                       | `""`                               |
| `agent.command`                             | Override default container command (useful when using custom images)                                                                                          | `[]`                               |
| `agent.args`                                | Override default container args (useful when using custom images)                                                                                             | `[]`                               |
| `agent.livenessProbe.enabled`               | Enable livenessProbe on Wazuh Agent containers                                                                                                                | `true`                             |
| `agent.livenessProbe.initialDelaySeconds`   | Initial delay seconds for livenessProbe                                                                                                                       | `40`                               |
| `agent.livenessProbe.periodSeconds`         | Period seconds for livenessProbe                                                                                                                              | `10`                               |
| `agent.livenessProbe.timeoutSeconds`        | Timeout seconds for livenessProbe                                                                                                                             | `10`                               |
| `agent.livenessProbe.failureThreshold`      | Failure threshold for livenessProbe                                                                                                                           | `5`                                |
| `agent.readinessProbe.enabled`              | Enable readinessProbe on Wazuh Agent containers                                                                                                               | `true`                             |
| `agent.readinessProbe.initialDelaySeconds`  | Initial delay seconds for readinessProbe                                                                                                                      | `40`                               |
| `agent.readinessProbe.periodSeconds`        | Period seconds for readinessProbe                                                                                                                             | `10`                               |
| `agent.readinessProbe.timeoutSeconds`       | Timeout seconds for readinessProbe                                                                                                                            | `10`                               |
| `agent.readinessProbe.failureThreshold`     | Failure threshold for readinessProbe                                                                                                                          | `5`                                |
| `agent.resources.limits`                    | The resources limits for the Wazuh Agent containers                                                                                                           | `{}`                               |
| `agent.resources.requests`                  | The requested resources for the Wazuh Agent containers                                                                                                        | `{}`                               |
| `agent.containerSecurityContext.enabled`    | Enable container security context                                                                                                                             | `true`                             |
| `agent.containerPorts.http`                 | Wazuh Agent container port for http                                                                                                                           | `5000`                             |
| `agent.labels`                              | Map of labels to add to the daemonset                                                                                                                         | `{}`                               |
| `agent.annotations`                         | Annotations for Wazuh Agent primary pods                                                                                                                      | `{}`                               |
| `agent.podLabels`                           | Map of labels to add to the pods                                                                                                                              | `{}`                               |
| `agent.podAnnotations`                      | Map of annotations to add to the pods                                                                                                                         | `{}`                               |
| `agent.updateStrategy`                      | Wazuh Agent daemonset update strategy                                                                                                                         |                                    |
| `agent.updateStrategy.type`                 | Wazuh Agent daemonset update strategy type                                                                                                                    | `RollingUpdate`                    |
| `agent.updateStrategy.rollingUpdate`        | Wazuh Agent daemonset update strategy parameters                                                                                                              | `{}`                               |
| `agent.extraVolumeMounts`                   | Optionally specify extra list of additional volumeMounts for the Wazuh Agent container(s)                                                                     | `[]`                               |
| `agent.extraVolumes`                        | Optionally specify extra list of additional volumes for the Wazuh Agent pod(s)                                                                                | `[]`                               |
| `agent.extraPodSpec`                        | Optionally specify extra PodSpec for the Wazuh Agent pod(s)                                                                                                   | `{}`                               |
