
job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]

    group "[[.SERVICE_ID]]" {

      count = 1

      network {
        mode = "host"
        port "meshsense" { 
          to = 6052
          static = 6052
        }
      }

      task "[[.SERVICE_ID]]" {
        driver = "docker"
        config {
          image = "meshsense/meshsense"
          ports = ["meshsense"]
          mount {
            type = "bind"
            target = "/config"
            source = "/data/meshsense"
            readonly = false
          }

          network_mode = "host"
          privileged   = true
        }

        resources {
          cpu    = 500
          memory = 256
        }

        service {
          provider = "nomad"
          port = "meshsense"
          name ="meshsense"
          tags = [
           "logging", 
           "dashboard", 
           "icon=meshsense", 
           "description=meshsense web ui for meshtastic."
          ]
        }

        env {
          TZ = "Europe/Prague"
        }
      }
    }
  }




