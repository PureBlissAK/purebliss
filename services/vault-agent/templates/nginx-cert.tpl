{{- with secret "pki-letsencrypt/issue/nginx-role" "common_name=dev.purebliss.app" -}}
{{ .Data.certificate }}
{{- end -}}
