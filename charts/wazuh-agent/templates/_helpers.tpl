{{/*
Expand the name of the chart.
*/}}
{{- define "wazuhAgent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wazuhAgent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wazuhAgent.labels" -}}
helm.sh/chart: {{ include "wazuhAgent.chart" . }}
{{ include "wazuhAgent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wazuhAgent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wazuhAgent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return the proper Wazuh Agent image name
*/}}
{{- define "wazuhAgent.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.wazuhAgent.image "global" .Values.global) }}
{{- end -}}

{{/*
Create a default fully qualified Wazuh Agent name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "wazuhAgent.fullname" -}}
{{- $name := default "wazuh-agent" .Values.nameOverride -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "common.names.fullname" .) $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}


{{/*
Return the proper Docker Image Registry Secret Names for Wazuh Agent
*/}}
{{- define "wazuhAgent.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.wazuhAgent.image) "global" .Values.global) }}
{{- end -}}
