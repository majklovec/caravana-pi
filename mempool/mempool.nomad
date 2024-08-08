job "[[.SERVICE_ID]]" {
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    type = "service"

    group "[[.SERVICE_ID]]" {

    count = 1

    task "web" {
      driver = "docker"

      env {
        FRONTEND_HTTP_PORT = "8080"
        BACKEND_MAINNET_HTTP_HOST = "api"
      }

      config {
        image = "mempool/frontend:latest"
        ports = ["web"]
        command = ["./wait-for", "db:3306", "--timeout=720", "--", "nginx", "-g", "daemon off;"]
      }

      restart {
        attempts = 10
        interval = "5m"
        delay = "25s"
        mode = "delay"
      }

      resources {
        network {
          port "web" {
            static = 80
          }
        }
      }
    }
  

    task "api" {
      driver = "docker"

      env {
        MEMPOOL_BACKEND       = "none"
        CORE_RPC_HOST         = "172.27.0.1"
        CORE_RPC_PORT         = "8332"
        CORE_RPC_USERNAME     = "mempool"
        CORE_RPC_PASSWORD     = "mempool"
        DATABASE_ENABLED      = "true"
        DATABASE_HOST         = "db"
        DATABASE_DATABASE     = "mempool"
        DATABASE_USERNAME     = "mempool"
        DATABASE_PASSWORD     = "mempool"
        STATISTICS_ENABLED    = "true"
      }

      config {
        image = "mempool/backend:latest"
        command = ["./wait-for-it.sh", "db:3306", "--timeout=720", "--strict", "--", "./start.sh"]
        volumes = [
          "/data/mempool/cache:/backend/cache"
        ]
      }

      restart {
        attempts = 10
        interval = "5m"
        delay = "25s"
        mode = "delay"
      }

      resources {
        network {
          port "api" {
            static = 8080
          }
        }
      }
    }

    task "db" {
      driver = "docker"

      env {
        MYSQL_DATABASE      = "mempool"
        MYSQL_USER          = "mempool"
        MYSQL_PASSWORD      = "mempool"
        MYSQL_ROOT_PASSWORD = "admin"
      }

      config {
        image = "mariadb:10.5.21"
        volumes = [
          "/data/mempool/db:/var/lib/mysql"
        ]
      }

      restart {
        attempts = 10
        interval = "5m"
        delay = "25s"
        mode = "delay"
      }
    }
  }
}
