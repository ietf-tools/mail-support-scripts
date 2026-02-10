{{/*
Expand the name of the chart.
*/}}
{{- define "mail-support-scripts.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mail-support-scripts.fullname" -}}
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
{{- define "mail-support-scripts.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mail-support-scripts.labels" -}}
helm.sh/chart: {{ include "mail-support-scripts.chart" . }}
{{ include "mail-support-scripts.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mail-support-scripts.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mail-support-scripts.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mail-support-scripts.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mail-support-scripts.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Init container that clones the scripts repo via HTTPS.
*/}}
{{- define "mail-support-scripts.fetchScriptsInitContainer" -}}
- name: fetch-scripts
  image: "{{ .Values.gitImage.repository }}:{{ .Values.gitImage.tag }}"
  imagePullPolicy: {{ .Values.gitImage.pullPolicy }}
  command:
    - sh
    - -c
    - |
      git -c advice.detachedHead=false clone --depth 1 --branch {{ .Chart.Version }} {{ .Values.scriptsRepo }} /repo
  volumeMounts:
    - name: repo
      mountPath: /repo
{{- end }}

{{/*
Volumes for cloned repo.
*/}}
{{- define "mail-support-scripts.scriptVolumes" -}}
- name: repo
  emptyDir: {}
{{- end }}

{{/*
Volume mount for the scripts directory in the main container.
*/}}
{{- define "mail-support-scripts.scriptVolumeMount" -}}
- name: repo
  mountPath: /scripts
  subPath: scripts
  readOnly: true
{{- end }}
