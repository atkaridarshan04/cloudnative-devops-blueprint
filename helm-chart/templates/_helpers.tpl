{{/*
Expand the name of the chart.
*/}}
{{- define "mern-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mern-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mern-chart.labels" -}}
helm.sh/chart: {{ include "mern-chart.chart" . }}
{{ include "mern-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mern-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mern-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the shared ServiceAccount every service's pods use.
*/}}
{{- define "mern-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (printf "%s-sa" .Release.Name) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
