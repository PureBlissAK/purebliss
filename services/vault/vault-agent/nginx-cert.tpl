{{- with secret "secret/nginx/certs" -}}
{{ .Data.data["fullchain.pem"] }}
{{- end -}}
