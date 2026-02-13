
{{/*
Return the name of the Secret used to store the runtime configuration
*/}}
{{- define "cloudbeaver.secretRuntimeConfName" -}}
{{ template "common.names.fullname" . }}-runtime-conf
{{- end -}}

{{/*
Return the correct hostname
*/}}
{{- define "cloudbeaver.hostname" -}}
{{- coalesce (tpl .Values.hostname $) (tpl .Values.ingress.hostname $) -}}
{{- end -}}
