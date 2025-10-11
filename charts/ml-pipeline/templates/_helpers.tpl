{{/*
Expand the name of the chart.
*/}}
{{- define "ml-pipeline.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ml-pipeline.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ml-pipeline.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ml-pipeline.labels" -}}
helm.sh/chart: {{ include "ml-pipeline.chart" . }}
{{ include "ml-pipeline.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ml-pipeline.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ml-pipeline.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ml-pipeline.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ml-pipeline.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service
*/}}
{{- define "ml-pipeline.serviceName" -}}
{{- include "ml-pipeline.fullname" . }}
{{- end }}

{{/*
Create the name of the ingress
*/}}
{{- define "ml-pipeline.ingressName" -}}
{{- include "ml-pipeline.fullname" . }}
{{- end }}

{{/*
Create the name of the configmap
*/}}
{{- define "ml-pipeline.configMapName" -}}
{{- include "ml-pipeline.fullname" . }}-config
{{- end }}

{{/*
Create the name of the secret
*/}}
{{- define "ml-pipeline.secretName" -}}
{{- include "ml-pipeline.fullname" . }}-secret
{{- end }}

{{/*
Create the name of the persistent volume claim
*/}}
{{- define "ml-pipeline.pvcName" -}}
{{- include "ml-pipeline.fullname" . }}
{{- end }}

{{/*
Create the name of the service monitor
*/}}
{{- define "ml-pipeline.serviceMonitorName" -}}
{{- include "ml-pipeline.fullname" . }}
{{- end }}

{{/*
Create the name of the network policy
*/}}
{{- define "ml-pipeline.networkPolicyName" -}}
{{- include "ml-pipeline.fullname" . }}
{{- end }}

{{/*
Create the name of the pod security policy
*/}}
{{- define "ml-pipeline.podSecurityPolicyName" -}}
{{- include "ml-pipeline.fullname" . }}
{{- end }}
