job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    update {
      stagger      = "30s"
      max_parallel = 1
    }

    group "[[.SERVICE_ID]]" {
      count = 1

      network {
        port "http" {
          static = 80
        }

        port "https" {
          static = 443
        }

        #      port "api" {
        #        static = 8080
        #      }

        #      port "metrics" {
        #        static = 9082
        #      }
      }

      service {
        provider = "nomad"
        name     = "traefik-dashboard"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.dashboard.rule=Host(`[[.DEPLOY_HOST]]`)",
          "traefik.http.routers.dashboard.service=api@internal",
          "traefik.http.routers.dashboard.entrypoints=websecure",
          "traefik.http.routers.dashboard.middlewares=basic-auth",
          "traefik.http.middlewares.basic-auth.basicauth.users=[[.TRAEFIK_DASHBOARD_USER]]:[[.TRAEFIK_DASHBOARD_PASSWORD]]",
        ]

        port = "https"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "5s"
        }
      }

      task "loadbalancer" {
        driver = "docker"

        config {
          image = "traefik"
          ports = ["http", "https"]
          args  = ["--configFile=local/traefik.yaml"]
          mount {
            type     = "bind"
            target   = "/acme"
            source   = "/data/traefik-acme"
            readonly = false
          }

        }

        template {
          data = <<EOF
            accessLog:
              format: json
              filters:
                statusCodes:
                  - "200"
                  - "300-302"
                retryAttempts: true
                minDuration: "10ms"
            experimental:
              http3: true
            entryPoints:
              web:
                address: ':80'
                http:
                  redirections:
                    entryPoint: 
                      to: websecure
              websecure:
                address: ':443'
                http:
                  tls:
                    certResolver: le
              grpc:
                address: ':7344'
              metrics:
                address: ':9082'
            certificatesResolvers:
              le:
                acme:
                  email: [[.EMAIL]]
                  storage: /acme/acme.json
                  httpChallenge:
                    entryPoint: web
            api:
              dashboard: true
              insecure: true
            log:
              level: DEBUG
              format: json
            ping:
              entrypoint: web
            metrics:
              prometheus:
                entryPoint: metrics
            providers:
              file:
                filename: /local/traefik-routes.yaml
              nomad:
                # constraints: "Tag(`a.tag.name`)"
#                defaultRule: PathPrefix(`/{{"{{"}} normalize .Name | lower {{"}}"}}`)
                endpoint:
                  address: http://172.17.0.1:4646
                  token: "[[.NOMAD_TOKEN]]"
                exposedByDefault: false
EOF

          destination = "local/traefik.yaml"
        }

        template {
          data        = <<EOF
http:
  routers:
    nomad:
      rule: Host(`[[.NOMAD_DASHBOARD]]`)
      service: nomad
      tls:
        certResolver: le
  services:
    nomad:
      loadBalancer:
        servers:
          - url: "http://172.17.0.1:4646"
EOF
          destination = "local/traefik-routes.yaml"
        }

        resources {
          cpu    = 100
          memory = 128
        }
      }
    }
  }

