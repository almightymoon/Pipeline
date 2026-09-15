{{- /*
Image reference: prefer digest, never default to latest.
*/ -}}
{{- define "demo-app.image" -}}
{{- if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else if and .Values.image.tag (ne .Values.image.tag "latest") -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- else -}}
{{ fail "image.digest is required (or a non-latest tag for local only)" }}
{{- end -}}
{{- end -}}

{{- define "demo-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
