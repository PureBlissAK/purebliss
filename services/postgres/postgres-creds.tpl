POSTGRES_USER={{ with secret "database/creds/postgres-app" }}{{ .Data.username }}{{ end }}
POSTGRES_PASSWORD={{ with secret "database/creds/postgres-app" }}{{ .Data.password }}{{ end }}
