{{/*
Renders services.<name>.env as container env entries.
Call: include "mern-chart.envVars" (dict "env" $svc.env "root" $)
valueFrom.*.name is a suffix - release name is prefixed.
*/}}
{{- define "mern-chart.envVars" -}}
{{- range $key, $entry := .env }}
- name: {{ $key }}
{{- if $entry.valueFrom }}
  valueFrom:
    {{- if $entry.valueFrom.configMapKeyRef }}
    configMapKeyRef:
      name: {{ $.root.Release.Name }}-{{ $entry.valueFrom.configMapKeyRef.name }}
      key: {{ $entry.valueFrom.configMapKeyRef.key }}
    {{- end }}
    {{- if $entry.valueFrom.secretKeyRef }}
    secretKeyRef:
      name: {{ $.root.Release.Name }}-{{ $entry.valueFrom.secretKeyRef.name }}
      key: {{ $entry.valueFrom.secretKeyRef.key }}
    {{- end }}
{{- else }}
  value: {{ $entry.value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Mongo connection string for backend's ConfigMap. Assumes the `mongodb` services key name.
*/}}
{{- define "mern-chart.mongoURL" -}}
mongodb://{{ .Values.mongodb.username }}:{{ .Values.mongodb.password }}@{{ .Release.Name }}-mongodb-statefulset-0.{{ .Release.Name }}-mongodb-service.{{ .Values.namespace }}.svc.cluster.local:27017/{{ .Values.mongodb.dbName }}?authSource={{ .Values.mongodb.authSource }}
{{- end }}
