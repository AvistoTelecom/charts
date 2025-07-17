
{{/*
Return the name of the Secret used to store the runtime configuration
*/}}
{{- define "cloudbeaver.secretRuntimeConfName" -}}
{{ template "common.names.fullname" . }}-runtime-conf
{{- end -}}
