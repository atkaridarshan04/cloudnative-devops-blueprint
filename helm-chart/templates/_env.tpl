{{/*
Render a services.<name>.env map as a list of container env entries.
Call as: include "mern-chart.envVars" (dict "env" $svc.env "root" $)
Each entry is either a literal `value`, or a `valueFrom.configMapKeyRef`/
`valueFrom.secretKeyRef` where `name` is given as a suffix - this chart
prefixes it with the release name, the same convention every other
resource name in this chart already follows, since these configmaps/
secrets are generated per-release rather than referencing something
with a fixed external name.
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
MongoDB connection string for the backend's ConfigMap. Host follows the
naming convention service.yaml/statefulset.yaml already use for the
`mongodb` entry in .Values.services (<release>-mongodb-statefulset-0 /
<release>-mongodb-service) - not a separately configurable name, so if
that services key is ever renamed, this must change with it.
*/}}
{{- define "mern-chart.mongoURL" -}}
mongodb://{{ .Values.mongodb.username }}:{{ .Values.mongodb.password }}@{{ .Release.Name }}-mongodb-statefulset-0.{{ .Release.Name }}-mongodb-service.{{ .Values.namespace }}.svc.cluster.local:27017/{{ .Values.mongodb.dbName }}?authSource={{ .Values.mongodb.authSource }}
{{- end }}
