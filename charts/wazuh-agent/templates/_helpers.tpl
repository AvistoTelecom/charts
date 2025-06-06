{{/*
Expand the name of the chart.
*/}}
{{- define "agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agent.labels" -}}
helm.sh/chart: {{ include "agent.chart" . }}
{{ include "agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return the proper Wazuh Agent image name
*/}}
{{- define "agent.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.agent.image "global" .Values.global) }}
{{- end -}}

{{/*
Create a default fully qualified Wazuh Agent name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "agent.fullname" -}}
{{- $name := default "wazuh-agent" .Values.nameOverride -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "common.names.fullname" .) $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* 
Get the agent configuration ConfigMap name. 
*/}}
{{- define "agent.configmapName" -}}
{{- if .Values.agent.existingConfigmap -}}
{{- printf "%s" (tpl .Values.agent.existingConfigmap $) -}}
{{- else -}}
{{- printf "%s-ossec-conf" (include "agent.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the password secret.
*/}}
{{- define "agent.secretName" -}}
{{- if .Values.global.postgresql.auth.existingSecret -}}
    {{- printf "%s" (tpl .Values.global.postgresql.auth.existingSecret $) -}}
{{- else if .Values.auth.existingSecret -}}
    {{- printf "%s" (tpl .Values.auth.existingSecret $) -}}
{{- else -}}
    {{- printf "%s" (include "postgresql.v1.chart.fullname" .) -}}
{{- end -}}
{{- end -}}