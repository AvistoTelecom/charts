{{- define "pinniped-supervisor.apiServiceName" -}}
{{- printf "%s-api" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Label Pinniped puts on the objects it creates. Kept distinct from the chart's matchLabels.
*/}}
{{- define "pinniped-supervisor.appLabel" -}}
app: {{ include "common.names.fullname" . }}
{{- end -}}

{{- define "pinniped-supervisor.validate" -}}
{{- if and .Values.httpRoute.enabled (not .Values.httpRoute.hostname) -}}
{{- fail "httpRoute.hostname is required when httpRoute.enabled=true" -}}
{{- end -}}
{{- end -}}

{{- define "pinniped-supervisor.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}
