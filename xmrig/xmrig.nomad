job "[[.SERVICE_ID]]" {
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    type = "service"

    group "[[.SERVICE_ID]]" {

      count = 1
      network {
        port "xmrig" { to = 8000 }

        dns {
          servers = ["8.8.8.8", "8.8.4.4"]
        }
      }
      ///bin/config.json
      task "xmrig" {
        driver = "docker"
        config {
          image = "majkl/xmrig:arm"
          ports = ["xmrig"]
          args = [
            "--api-worker-id [[.WORKER_ID]]",
            "--http-host=0.0.0.0",
            "--http-port=8000",
            "--url=[[.POOL]]",
            "--user=[[.WALLET]]",
            "--tls",
            "--coin=monero",
            "--pass=x",
            "--rig-id=[[.WORKER_ID]]"
          ]
          privileged = true
        }


        // "--max-cpu-usage=100", "--cpu-priority=5", "--coin=XMR", "--tls", "-o", "xmr.2miners.com:12222", "-u", "47awNeyfVMgBxARBh19jSFCPTDxuFbVdyD9evJgr69b1TCVAcXEAzvNdjjPZ8ErEegBWysdoducfvH7W5DUEBbMBQuCXnQT", "-p", "x"]

        resources {
          cpu    = 4000
          memory = 4096
        }

        service {
          provider = "nomad"
          port = "xmrig"
        }
      }
    }
  }