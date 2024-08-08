job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]

  group "ethereum" {
        network {
          port "http" {
            static = 8545
          }

          port "p2p" {
            static = 30303
          }
        }

    task "client-go" {
      driver = "docker"

      config {
        image = "ethereum/client-go"
        ports = ["http", "p2p"]
        volumes = [
          "/data/ethereum:/root/.ethereum",
        ]
        args = [
          "--http",
          "--http.addr", "0.0.0.0",
          "--syncmode", "snap"
        ]
      }
    }
  }
}