PLANE_DB_USER={{ with secret "database/creds/plane" }}{{ .Data.username }}{{ end }}
PLANE_DB_PASSWORD={{ with secret "database/creds/plane" }}{{ .Data.password }}{{ end }}
PLANE_DB_HOST=purebliss-postgres
PLANE_DB_PORT=5432
PLANE_DB_NAME=plane
