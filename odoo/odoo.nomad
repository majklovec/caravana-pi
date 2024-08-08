job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    group "[[.SERVICE_ID]]" {
      count = 1

      network {
        port "web" { to = 8069 }
        port "livechat" { to = 8072 }
        port "db" { to = 5432 }
      }

      task "[[.SERVICE_ID]]" {
        driver = "docker"
        config {
          image = "[[.ODOO_IMAGE]]"
          ports = ["web", "livechat"]
          volumes = [
            "local/odoo.conf:/etc/odoo/odoo.conf"
          ]
          mount {
            type     = "bind"
            source   = "/data/[[.SERVICE_ID]]/web"
            target   = "/var/lib/odoo"
            readonly = false
          }
          mount {
            type     = "bind"
            readonly = false
            source   = "/data/[[.SERVICE_ID]]/extra-addons"
            target   = "/mnt/extra-addons"

          }
        }

        env {
          HOST     = "${NOMAD_HOST_IP_db}"
          PORT     = "${NOMAD_HOST_PORT_db}"
          USER     = "[[.DB_USER]]"
          PASSWORD = "[[.DB_PASSWORD]]"
        }

        resources {
          cpu    = 500
          memory = 512
        }

        template {
          data        = <<EOH
[options]
addons_path = /mnt/extra-addons
data_dir = /var/lib/odoo
; admin_passwd = admin
; csv_internal_sep = ,
; db_maxconn = 64
; db_name = False
; db_template = template1
; dbfilter = .*
; debug_mode = False
; email_from = False
; limit_memory_hard = 2684354560
; limit_memory_soft = 2147483648
; limit_request = 8192
; limit_time_cpu = 60
; limit_time_real = 120
; list_db = True
; log_db = False
; log_handler = [':INFO']
; log_level = info
; logfile = None
; longpolling_port = 8072
; max_cron_threads = 2
; osv_memory_age_limit = 1.0
; osv_memory_count_limit = False
; smtp_password = False
; smtp_port = 25
; smtp_server = localhost
; smtp_ssl = False
; smtp_user = False
; workers = 0
; xmlrpc = True
; xmlrpc_interface = 
; xmlrpc_port = 8069
; xmlrpcs = True
; xmlrpcs_interface = 
; xmlrpcs_port = 8071
EOH
          destination = "local/odoo.conf"
        }

        service {
          provider = "nomad"
          name     = "[[.SERVICE_ID]]"
          port     = "web"

          tags = [
            "traefik.enable=true",
            "traefik.http.routers.[[.SERVICE_ID]].rule=Host(`[[.DEPLOY_HOST]]`)"
          ]

          check {
            name     = "alive"
            type     = "http"
            path     = "/"
            interval = "10s"
            timeout  = "2s"
          }
        }

        service {
          name     = "[[.SERVICE_ID]]-livechat"
          provider = "nomad"
          port     = "livechat"
        }
      }


      task "[[.SERVICE_ID]]-db" {
        driver = "docker"
        config {
          image = "postgres:13"
          ports = ["db"]
          mount {
            type     = "bind"
            target   = "/var/lib/postgresql/data"
            source   = "/data/[[.SERVICE_ID]]/db"
            readonly = false
          }

        }

        lifecycle {
          hook    = "prestart"
          sidecar = true
        }

        resources {
          cpu    = 500
          memory = 512
        }
        env {
          POSTGRES_DB       = "postgres"
          POSTGRES_PASSWORD = "[[.DB_PASSWORD]]"
          POSTGRES_USER     = "[[.DB_USER]]"
        }

        service {
          provider = "nomad"
          name     = "[[.SERVICE_ID]]-db"
          port     = "db"
        }
      }
    }
  }
