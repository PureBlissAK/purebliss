disable_mlock = true

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:18220"
  tls_disable = 1
}

api_addr = "http://dev.purebliss.app:18220"
log_level = "debug"
ui = true
