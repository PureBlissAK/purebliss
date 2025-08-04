{
  "database": {
    "host": "{{ with secret "database/creds/postgres-role" }}{{ .Data.username }}@purebliss-postgres{{ end }}",
    "username": "{{ with secret "database/creds/postgres-role" }}{{ .Data.username }}{{ end }}",
    "password": "{{ with secret "database/creds/postgres-role" }}{{ .Data.password }}{{ end }}",
    "database": "postgres",
    "updated_at": "{{ timestamp }}"
  }
}
