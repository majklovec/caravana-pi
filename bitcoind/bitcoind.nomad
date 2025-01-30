
job "[[.SERVICE_ID]]" {
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    type = "service"

    group "[[.SERVICE_ID]]" {
      count = 1

      network {
        port "bitcoin" { 
          to = 8333 
          static = 8333
        }
        port "bitcoinsecure" { 
          to = 8334 
          static = 8334
        }
        port "bitcoinrpc" { 
          to = 8332 
          static = 8332
        }

        port "zmqpubrawblock" { 
          to = 29000  
          static = 29000
        }
        port "zmqpubrawtx" { 
          to = 29001  
          static = 29001
        }
        port "zmqpubhashtx" { 
          to = 29000  
        }
        port "zmqpubhashblock" { 
          to = 29000  
        }
        port "zmqpubsequence" { 
          to = 29002          
          static = 29002
        }

        port "socks" { 
          to = 9050 
          static = 9050
        }
        port "control" { 
          to = 9051 
          static = 9051
        }
        port "i2pd" { 
          to = 7656 
          static = 7656
        }
        port "exporter" { 
          to = 9332
	  static = 9332
        }
      }

   task "tor" {
        driver = "docker"
        config {
          image   = "majkl/tor:arm"
          ports   = ["socks", "control"]
          command = "tor"
          args    = ["-f", "/local/torrc"]
        }

        resources {
          cpu    = 200
          memory = 64

        }



        template {
          data        = <<EOF
            SocksPort 0.0.0.0:9050
            ControlPort 0.0.0.0:9051
            CookieAuthentication 1
            CookieAuthFileGroupReadable 1
          EOF
          destination = "local/torrc"
        }

        //      HiddenServiceDir /local/tor
        // HiddenServicePort



        service {
          provider = "nomad"
          name="tor-socks"
          port = "socks"
        }
        service {
          provider = "nomad"
          name="tor-control"
          port = "control"
        }
      }

     task "i2pd" {
        driver = "docker"
        config {
          image = "purplei2p/i2pd"
          ports = ["i2pd"]
          args  = ["--sam.enabled=true", "--sam.address=0.0.0.0", "--sam.port=7656", "--loglevel=debug"]

        }

        resources {
          cpu    = 200
          memory = 64
        }

        service {
          provider = "nomad"
          name="i21pd"
          port = "i2pd"
        }        
      }

  task "exporter" {
      driver = "docker"
      config {
        image = "jvstein/bitcoin-prometheus-exporter:latest"
        ports = ["exporter"]
      }

      resources {
        cpu    = 100
        memory = 64
      }


      env {
        BITCOIN_RPC_HOST = "${NOMAD_IP_bitcoinrpc}"
        BITCOIN_RPC_USER = "rpcuser"
        BITCOIN_RPC_PASSWORD = "rpcpassword"
        REFRESH_SECONDS = "1"
        LOG_LEVEL = "DEBUG"
      }



      service {
        provider = "nomad"
        name = "bitcoinexport"
        port = "exporter"

        tags = [
	  "prometheus=/metrics"
        ]
      }
    }

      task "bitcoin" {
        driver = "docker"

        config {
          image   = "majkl/bitcoind:arm"
          ports   = [
            "bitcoin", 
            "bitcoinsecure", 
            "bitcoinrpc", 
            "zmqpubrawblock",
            "zmqpubrawtx",
            "zmqpubhashtx",
            "zmqpubhashblock",
            "zmqpubsequence"        
          ]
          entrypoint = []
          command = "bitcoind"
          args    = ["-conf=/local/bitcoind.conf"]

          mount {
            type = "bind"
            target = "/data"
            source = "/data/bitcoind"
            readonly = false
          }
        }

        resources {
          cpu    = 500
          memory = 256
        }

        template {
          data        = <<EOF
# [chain]

# [core]
# Maximum database cache size in MiB
dbcache=450
txindex=1
datadir=/data

server=1
rpcuser=rpcuser
rpcpassword=rpcpassword
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0
rpcport=8332

printtoconsole=1
disablewallet=1
txindex=1
zmqpubrawblock=tcp://0.0.0.0:29000
zmqpubrawtx=tcp://0.0.0.0:29001
zmqpubhashtx=tcp://0.0.0.0:29000
zmqpubhashblock=tcp://0.0.0.0:29000
zmqpubsequence=tcp://0.0.0.0:29002

# [network]
# Connect to peers over the clearnet.
onlynet=ipv4
#onlynet=ipv6

# Use separate SOCKS5 proxy <ip:port> to reach peers via Tor hidden services.
onlynet=onion
onion={{ env "NOMAD_ADDR_socks" }}
# Tor control <ip:port> and password to use when onion listening enabled.
torcontrol={{ env "NOMAD_ADDR_control" }}
#torpassword=moneyprintergobrrr

# I2P SAM proxy <ip:port> to reach I2P peers.
i2psam={{ env "NOMAD_ADDR_i2pd" }}
onlynet=i2p

# Enable/disable incoming connections from peers.
listen=1
listenonion=1
i2pacceptincoming=1

# Required to configure Tor control port properly
[main]
bind=0.0.0.0:8333
bind=0.0.0.0:8334=onion
          EOF
          destination = "local/bitcoind.conf"
          // env         = true
        }

        service {
          provider = "nomad"
          port = "bitcoin"
          name ="BitcoinD"
          tags = [
            "logging",
            "dashboard",
            "icon=bitcoind"
          ]
        }

        service {
          provider = "nomad"
          port = "bitcoinrpc"
          name ="bitcoinrpc"
        }        

        service {
          provider = "nomad"
          name="bitcoinsecure"
          port = "bitcoinsecure"
        } 

        service {
          provider = "nomad"
          name = "zmqpubrawblock"
          port = "zmqpubrawblock"
        }
        service {
          provider = "nomad"
          name = "zmqpubrawtx"
          port = "zmqpubrawtx"
        }
        service {
          provider = "nomad"
          name = "zmqpubhashtx"
          port = "zmqpubhashtx"
        }
        service {
          provider = "nomad"
          name = "zmqpubhashblock"
          port = "zmqpubhashblock"
        }
        service {
          provider = "nomad"
          name = "zmqpubsequence"
          port = "zmqpubsequence"
        }
      }
    }
  }
