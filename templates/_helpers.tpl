{{- define "sftpplus.fullname" -}}
{{- printf "%s-sftpplus" .Release.Name | trunc 54 | trimSuffix "-" -}}
{{- end -}}

{{- define "sftpplus.adminName" -}}
{{- printf "%s-admin" (include "sftpplus.fullname" .) -}}
{{- end -}}

{{- define "sftpplus.workerName" -}}
{{- printf "%s-worker" (include "sftpplus.fullname" .) -}}
{{- end -}}

{{- define "sftpplus.configChecksum" -}}
{{- printf "%s%s%s%s" (.Files.Get "files/server-admin.ini.init") (.Files.Get "files/server-worker.ini.init") (.Files.Get "files/admin-init.sh") (.Files.Get "files/worker-init.sh") | sha256sum -}}
{{- end -}}
