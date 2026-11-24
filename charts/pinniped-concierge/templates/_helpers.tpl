{{/*
Pinniped image, shared by the Concierge and the kube-cert-agent pods it spawns
*/}}
{{- define "pinniped-concierge.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Names Pinniped is told about in its config, all derived from the fullname.
*/}}
{{- define "pinniped-concierge.apiServiceName" -}}
{{- printf "%s-api" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pinniped-concierge.proxyServiceName" -}}
{{- printf "%s-proxy" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pinniped-concierge.agentServiceAccountName" -}}
{{- printf "%s-kube-cert-agent" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pinniped-concierge.impersonationServiceAccountName" -}}
{{- printf "%s-impersonation-proxy" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Label Pinniped puts on the objects it creates (and that its own LoadBalancer/ClusterIP services select on).
Kept distinct from the chart's matchLabels so the kube-cert-agent pods are never selected by the chart's Services.
*/}}
{{- define "pinniped-concierge.appLabel" -}}
app: {{ include "common.names.fullname" . }}
{{- end -}}

{{/*
Validate values
*/}}
{{- define "pinniped-concierge.validate" -}}
{{- if .Values.tlsRoute.enabled -}}
{{- if not .Values.tlsRoute.hostname -}}
{{- fail "tlsRoute.hostname is required when tlsRoute.enabled=true" -}}
{{- end -}}
{{- if ne .Values.impersonationProxy.mode "enabled" -}}
{{- fail "impersonationProxy.mode must be \"enabled\" when tlsRoute.enabled=true (in \"auto\" mode the proxy is off whenever the kube-cert-agent works, leaving the route without backend)" -}}
{{- end -}}
{{- end -}}
{{- end -}}
