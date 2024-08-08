job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    group "[[.SERVICE_ID]]" {
      count = 1

      network {
        port "samba" { static = 139 }
        port "sambatcp" { static = 445 }
      }

      task "[[.SERVICE_ID]]" {
        driver = "docker"
        config {
          image = "dperson/samba"
          ports = ["samba", "sambatcp"]
          args = ["-p", "-g", "log level = 2 passdb:5 auth:10"]
          mount {
            type     = "bind"
            source   = "/data"
            target   = "/data"
            readonly = false
          }
        }

        env {
            USER = "majkl;absinth"
            SHARE = "share;/data/deluge/downloads;yes;no;no;majkl"
        }

        resources {
          cpu    = 500
          memory = 512
        }

        service {
          provider = "nomad"
          name     = "[[.SERVICE_ID]]"
          port     = "samba"

          check {
            name     = "alive"
            type     = "tcp"
            interval = "10s"
            timeout  = "2s"
          }
        }

        service {
          name     = "[[.SERVICE_ID]]-livechat"
          provider = "nomad"
          port     = "sambatcp"
        }
      }
    }
  }
