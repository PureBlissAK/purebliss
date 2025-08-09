{{- with secret "pki-letsencrypt/issue/nginx-role" "common_name=dev.purebliss.app" -}}
{{ .Data.private_key }}
{{- end -}}
