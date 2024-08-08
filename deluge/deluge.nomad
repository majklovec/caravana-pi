job "[[.SERVICE_ID]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    update {
      stagger      = "30s"
    }
    group "[[.SERVICE_ID]]" {
      count = 1
      network {
        port "web" {
          to = 8112
          static = 8112
        }
      }

      task "[[.SERVICE_ID]]" {
      driver = "docker"
      config {
        image = "linuxserver/deluge:arm64v8-latest"
        ports = ["web"]
          mount {
            type = "bind"
            target = "/downloads"
            source = "/data/deluge/downloads"
            readonly = false
          }
          mount {
            type = "bind"
            target = "/config"
            source = "/data/deluge/config"
            readonly = false
          }

      }

      resources {
        cpu    = 100
        memory = 32
      }

      service {
        name = "Deluge"
        provider = "nomad"
        port = "web"

        tags = [
          "dashboard",
          "icon=mqtt",
          "logging"
        ]

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

