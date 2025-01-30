
job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]

    group "[[.SERVICE_ID]]" {

      count = 1

      network {
        mode = "host"
        port "webui" { 
          to = 8080
          static = 8080
        }
        port "ollama" { 
          to = 11434
          static = 11434
        }
      }

      task "[[.SERVICE_ID]]" {
        driver = "docker"

        config {
          image = "ollama/ollama:latest"
          ports = ["ollama"]

          mount {
            type = "bind"
            target = "/root/.ollama"
            source = "/data/ollama/config"
            readonly = false
          }
          mount {
            type = "bind"
            target = "/code"
            source = "/data/ollama/code"
            readonly = false
          }

          tty = true
        }

        env {
          OLLAMA_KEEP_ALIVE = "24h"
          OLLAMA_HOST = "0.0.0.0"
        }

        restart {
          attempts = 3
          interval = "5m"
          delay = "30s"
          mode = "delay"
        }

        service {
          provider = "nomad"
          port = "ollama"
          name ="ollama"
          tags = [
           "logging", 
           "dashboard", 
           "icon=ollama", 
           "description=ollama"
          ]
        }
      }

      task "[[.SERVICE_ID]]-webui" {
        driver = "docker"

        config {
          image = "ghcr.io/open-webui/open-webui:main"
          ports = ["webui"]
#          volumes = ["local/ollama-webui:/app/backend/data"]
#          extra_hosts = ["host.docker.internal:host-gateway"]

#          mount {
#            type = "bind"
#            target = "/app/backend/data"
#            source = "/data/ollama/webui"
#            readonly = false
#          }

        }

        env {
          ENV = "dev"
          WEBUI_AUTH = "False"
          WEBUI_NAME = "Ollama"
          WEBUI_SECRET_KEY = "secret"
          OLLAMA_BASE_URL = "http://${NOMAD_HOST_IP_ollama}:${NOMAD_HOST_PORT_ollama}"
        }

        restart {
          attempts = 3
          interval = "5m"
          delay = "30s"
          mode = "delay"
        }

        service {
          name = "webui"
          provider = "nomad"
          port = "webui"
        }
      }
    }
  }




