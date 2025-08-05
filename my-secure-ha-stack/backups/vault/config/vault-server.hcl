storage "raft" {
  path = "/vault/data"
}

cluster_addr = "http://127.0.0.1:8201"

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

api_addr = "http://127.0.0.1:8200"
ui = true
