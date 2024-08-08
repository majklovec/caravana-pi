job "[[.SERVICE_ID]]" {
  type = "service"
  datacenters = [ [[range $index, $value := .DATACENTERS]][[if ne $index 0]],[[end]]"[[$value]]"[[end]] ]
    update {
      stagger      = "30s"
    }
    group "[[.SERVICE_ID]]" {
      count = 1
      network {
        port "http" {
          to = 3000
          static = 8081
        }
        port "mqtt" {
          to = 1883
          static = 1883
        }
        port "websockets" {
          to = 8083
          static = 8083
        }
      }

      task "[[.SERVICE_ID]]" {
      driver = "docker"
      config {
        image = "majkl/mosquitto:arm"
        args = ["-c", "/local/mosquitto.conf"]
        ports = ["websockets", "mqtt"]
      }

      template {
        data = <<EOF
max_queued_messages 200
message_size_limit 0
allow_zero_length_clientid true
allow_duplicate_messages false

listener 1883
listener 8083
protocol websockets

autosave_interval 900
autosave_on_changes false
#persistence true
#persistence_file mosquitto.db
allow_anonymous true
        EOF
        destination = "local/mosquitto.conf"
      }

      resources {
        cpu    = 100
        memory = 32
      }

      service {
        name = "Mosquitto"
        provider = "nomad"
        port = "websockets"

        tags = [
          "dashboard",
          "icon=mqtt",
          "logging"
        ]

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

      task "[[.SERVICE_ID]]-client" {
      driver = "docker"
      config {
        image = "majkl/mosquitto-client:arm"
        ports = ["http"]
#        command = "/busybox"
#        args = ["httpd", "-f", "-v", "-p", "3000", "-c", "/local/httpd.conf"]

        volumes = [
          "/local/config.js:/config.js",
        ]

      }

      template {
        data = <<EOF
websocketserver = '192.168.1.136';
websocketport = 8083;
        EOF
        destination = "local/config.js"
      }


      resources {
        cpu    = 100
        memory = 32
      }

      service {
        name = "MQTT"
        provider = "nomad"
        port = "http"

        tags = [
          "dashboard",
          "icon=mqtt",
          "logging"
        ]

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

