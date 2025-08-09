{{- with secret "secret/letsencrypt/certs" -}}
{{ .Data.data["fullchain.pem"] }}
{{- end -}}
