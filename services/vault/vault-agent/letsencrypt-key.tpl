{{- with secret "secret/letsencrypt/certs" -}}
{{ .Data.data["privkey.pem"] }}
{{- end -}}
