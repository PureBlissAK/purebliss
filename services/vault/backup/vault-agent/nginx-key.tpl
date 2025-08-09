{{- with secret "secret/nginx/certs" -}}
{{ .Data.data["privkey.pem"] }}
{{- end -}}
