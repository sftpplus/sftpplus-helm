{{- define "sftpplus.fullname" -}}
{{- if gt (len .Release.Name) 51 -}}
{{- printf "%s-%s" (trimSuffix "-" (trunc 42 .Release.Name)) (trunc 8 (sha256sum .Release.Name)) -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "sftpplus.adminName" -}}
{{- printf "%s-admin" (include "sftpplus.fullname" .) -}}
{{- end -}}

{{- define "sftpplus.workerName" -}}
{{- printf "%s-worker" (include "sftpplus.fullname" .) -}}
{{- end -}}

{{- define "sftpplus.configChecksum" -}}
{{- printf "%s%s%s%s%s%s%s%s%s" (.Files.Get "files/server-admin.ini.init") (.Files.Get "files/server-worker.ini.init") (.Files.Get "files/admin-init.sh") (.Files.Get "files/worker-init.sh") (.Values.ingress.host | default "") (toYaml .Values.adminService) (toYaml .Values.workerService) (toYaml .Values.workerDeployment.sync) (.Values.workerDeployment.poolName | default "") | sha256sum -}}
{{- end -}}

{{- define "sftpplus.storageClaimName" -}}
{{- default (printf "%s-storage" (include "sftpplus.fullname" .)) .Values.storage.claimName -}}
{{- end -}}

{{- define "sftpplus.podLabels" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $defaults := dict "app.kubernetes.io/name" "sftpplus" "app.kubernetes.io/instance" $root.Release.Name "app.kubernetes.io/component" $component -}}
{{- $custom := (index $root.Values (printf "%sDeployment" $component)).templateMetadata.labels | default dict -}}
{{- toYaml (mergeOverwrite $defaults $custom) -}}
{{- end -}}

{{- define "sftpplus.podAnnotations" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $defaults := dict "checksum/initialization" (include "sftpplus.configChecksum" $root) -}}
{{- $custom := (index $root.Values (printf "%sDeployment" $component)).templateMetadata.annotations | default dict -}}
{{- toYaml (mergeOverwrite (deepCopy $custom) $defaults) -}}
{{- end -}}

{{- define "sftpplus.adminHttpsName" -}}
{{- printf "%s-https" (include "sftpplus.adminName" .) -}}
{{- end -}}

{{- define "sftpplus.adminHttpName" -}}
{{- printf "%s-http" (include "sftpplus.adminName" .) -}}
{{- end -}}

{{- define "sftpplus.certificateSecretName" -}}
{{- default (printf "%s-tls" (include "sftpplus.fullname" .)) .Values.ingress.certificate.secretName -}}
{{- end -}}
