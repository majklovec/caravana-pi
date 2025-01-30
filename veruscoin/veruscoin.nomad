
job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]

    group "[[.SERVICE_ID]]" {

      count = 1

      # network {
      #   mode = "host"
      #   port "veruscoin" { 
      #     to = 6052
      #     static = 6052
      #   }
      # }

      task "[[.SERVICE_ID]]" {
        driver = "docker"
        config {
          image = "majkl/veruscoin:arm"
          ports = ["veruscoin"]
          mount {
            type = "bind"
            target = "/config"
            source = "/data/veruscoin"
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
          # port = "veruscoin"
          name ="veruscoin"
          tags = [
           "logging", 
           "dashboard", 
           "icon=veruscoin", 
           "description=veruscoin is a system to control your ESP8266/ESP32 by simple yet powerful configuration files and control them remotely through Home Automation systems."
          ]
        }

        env {
          TZ = "Europe/Prague"
        }
      }
    }
  }




