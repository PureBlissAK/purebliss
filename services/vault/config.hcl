disable_mlock = true

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:18200"
  tls_disable = 1
}

api_addr = "http://dev.purebliss.app:18200"
log_level = "debug"
ui = true
