job "[[.DEPLOY_HOST]]" {

  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    type = "service"

    group "[[.SERVICE_ID]]" {
      count = 1

      restart {
        attempts = 5
        delay    = "30s"
      }

      network {
        port "db" { to = 5432 }
        port "http" { to = 3000 }
      }

      task "[[.SERVICE_ID]]" {
        driver = "docker"
        config {
          image = "[[.GITEA_IMAGE]]"
          ports = ["http"]
          mount {
            type     = "bind"
            target   = "/data"
            source   = "/data/[[.SERVICE_ID]]/data"
            readonly = false
          }
        }

        env = {
          "APP_NAME"  = "[[.APP_NAME]]"
          "RUN_MODE"  = "[[.RUN_MODE]]"
          "SSH_PORT"  = "[[.SSH_PORT]]"
          "USER_UID"  = "[[.USER_UID]]"
          "USER_GID"  = "[[.USER_GID]]"
          "DB_TYPE"   = "[[.DB_TYPE]]"
          "DB_NAME"   = "[[.DB_NAME]]"
          "DB_USER"   = "[[.DB_USER]]"
          "DB_PASSWD" = "[[.DB_PASSWD]]"
        }

        resources {
          cpu    = 200
          memory = 256
        }

        service {
          provider = "nomad"
          port     = "http"
          name     = "traefik"

          tags = [
            "traefik.enable=true",
            "traefik.http.routers.[[.SERVICE_ID]].rule=Host(`[[.DEPLOY_HOST]]`)"
          ]
        }
      }

      task "[[.SERVICE_ID]]-db" {
        driver = "docker"
        config {
          image = "[[.DB_IMAGE]]"
          ports = ["db"]
          mount {
            type     = "bind"
            target   = "/var/lib/postgresql/data"
            source   = "/data/[[.SERVICE_ID]]/db"
            readonly = false
          }

        }
        env {
          "POSTGRES_USER"     = "[[.DB_NAME]]"
          "POSTGRES_PASSWORD" = "[[.DB_USER]]"
          "POSTGRES_DB"       = "[[.DB_PASSWD]]"
        }

        service {
          provider = "nomad"
          port     = "db"
          name     = "db"
        }
      }
    }
  }
