
job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]

    group "[[.SERVICE_ID]]" {

      count = 1

      network {
        mode = "host"
        port "esphome" { 
          to = 6052
          static = 6052
        }
      }

      task "[[.SERVICE_ID]]" {
        driver = "docker"
        config {
          image = "esphome/esphome"
          ports = ["esphome"]
          mount {
            type = "bind"
            target = "/config"
            source = "/data/esphome"
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
          port = "esphome"
          name ="esphome"
          tags = [
           "logging", 
           "dashboard", 
           "icon=esphome", 
           "description=ESPHome is a system to control your ESP8266/ESP32 by simple yet powerful configuration files and control them remotely through Home Automation systems."
          ]
        }

        env {
          TZ = "Europe/Prague"
        }
      }
    }
  }




