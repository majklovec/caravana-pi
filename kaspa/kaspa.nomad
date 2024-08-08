job "[[.DEPLOY_HOST]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]

  group "[[.SERVICE_ID]]" {
    count = 1

    network {
      mode = "host"
      port "rpc" { 
        to = 16110
        static = 16110
      }
      port "p2p" { 
        to = 16111
        static = 16111
      }
      port "wrpc" { 
        to = 17110
        static = 17110
      }
      port "wp2p" { 
        to = 17111
        static = 17111
      }
    }

    task "[[.SERVICE_ID]]" {
      driver = "docker"
      config {
        image = "supertypo/rusty-kaspad"
        ports = ["p2p", "rpc", "wp2p", "wrpc"]
        command = "kaspad"
        args = ["--yes", "--nologfiles", "--disable-upnp", "--utxoindex", "-b", "/data", "--rpclisten-borsh=0.0.0.0:17110"]
        mount {
          type = "bind"
          target = "/data"
          source = "/data/kaspad"
          readonly = false
        }
      }

      resources {
        cpu    = 500
        memory = 256
      }

      service {
        provider = "nomad"
        port = "rpc"
        name = "kaspad"
        tags = [
         "logging", 
         "dashboard", 
         "icon=kaspad", 
         "description=Kaspad is a full node implementation of the Kaspa protocol."
        ]
      }

      restart {
        mode = "delay"
        attempts = 2
        interval = "30s"
        delay = "15s"
      }
    }
  }
}
