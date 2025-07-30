// ============================================================================
// VAULT CONFIGURATION - UNRAID MACGYVER STACK
// ============================================================================

ui = true
disable_mlock = true

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = "true"  // TLS handled by Traefik
  
  // Enable CORS for UI access
  cors {
    enabled = true
    allowed_origins = ["*"]
  }
}

storage "file" {
  path = "/vault/data"
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"

// Logging
log_level = "info"
log_format = "json"

// Telemetry for Prometheus
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

// Default lease settings
default_lease_ttl = "168h"  // 7 days
max_lease_ttl = "720h"      // 30 days