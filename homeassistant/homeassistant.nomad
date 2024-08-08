job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    update {
      max_parallel      = 1
      min_healthy_time  = "10s"
      healthy_deadline  = "6m"
      progress_deadline = "10m"
      auto_revert       = false
      canary            = 0
    }
    migrate {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "15s"
      healthy_deadline = "10m"
    }
    group "homeassistant" {
      count = 1
      restart {
        attempts = 2
        interval = "30m"
        delay    = "15s"
        mode     = "fail"
      }
          
      network {
        port "http" { static = 8123 }
      }

      task "homeassistant" {
        driver = "docker"

        config {
          image        = "ghcr.io/home-assistant/aarch64-homeassistant:latest"
          network_mode = "host"
          privileged   = true
#          pull_activity_timeout = "5m"
          mount {
            type = "bind"
            target = "/config"
            source = "/data/homeassistant"
            readonly = false
          }
          mount {
            type = "bind"
            target = "/run/dbus"
            source = "/run/dbus"
            readonly = true
          }
          mount {
            type = "bind"
            target = "/media"
            source = "/media"
            readonly = false
          }
        }

        resources {
          cpu    = 800 # 500 MHz
          memory = 512 # 512 MB
     
        }

        service {
          provider = "nomad"
          name = "Home-Assistant"
          tags = ["dashboard", "logging", "icon=homeassistant"]
          port = "http"
          check {
            name     = "alive"
            path     = "/"
            type     = "http"
            interval = "10s"
            timeout  = "2s"
          }
        }
      }
    }
  }
