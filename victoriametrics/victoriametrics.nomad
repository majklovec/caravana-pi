job "[[.DEPLOY_HOST]]" {

  datacenters = [[ .DATACENTERS  | toJson ]]
  type        = "service"

  group "[[.SERVICE_ID]]" {
    count = 1

    restart {
      attempts = 5
      delay    = "30s"
    }

    network {
      port "http" {
        static = 8428
        to     = 8428
      }
    }



    task "[[.SERVICE_ID]]" {
      driver = "docker"

      config {
        image = "victoriametrics/victoria-metrics:v1.81.2"
        ports = ["http"]
        args = [
          "--storageDataPath=/storage",
          "--retentionPeriod=1",
          "--httpListenAddr=:8428",
          "--promscrape.configCheckInterval=10s",
          "--promscrape.config=/local/prometheus.yml"
        ]

        mount {
          type     = "bind"
          target   = "/storage"
          source   = "/data/[[.SERVICE_ID]]"
          readonly = false
        }

      }

      template {
        data        = <<EOF
global:
  scrape_interval: 10s
  external_labels:
    env: "dev"    

scrape_configs:
  - job_name: "nomad-agent"
    metrics_path: "/v1/metrics?format=prometheus"
    static_configs:
      - targets: ["172.17.0.1:4646", "10.93.9.17:4646", "192.168.222.68:4646"]
        labels:
          role: agent
    relabel_configs:
      - source_labels: [__address__]
        target_label: "cluster"
      - source_labels: [__address__]
        regex: "([^:]+):.+"
        target_label: "hostname"
        replacement: "nomad-agent-$1"      
  - job_name: "traefik"
    metrics_path: "/metrics"
    static_configs:
      - targets: ["10.93.9.17:8080"]
        labels:
          role: traefik

  - job_name: "node-exporter"
    metrics_path: "/metrics"
    static_configs:
      - targets: ["10.93.9.17:9100"]
        labels:
          role: node-exporter

  - job_name: "cadvisor"
    metrics_path: "/metrics"
    static_configs:
      - targets: ["172.17.0.1:9080"]
        labels:
          role: cadvisor

{{- range $tag, $services := nomadServices | byTag }}
  {{- if $tag | regexMatch "prometheus=(.*)" }}
    {{- range $services }}
      {{- range nomadService .Name }}
        {{- $path := $tag | replaceAll "prometheus=" "" }}
  - job_name: "{{ .Name }}"
    metrics_path: "{{ $path }}"
    static_configs:
      - targets:
          - "{{ .Address }}:{{ .Port }}"
        labels:
          service: "{{ .Name }}"
          instance: "{{ .ID }}"
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}       
EOF
        change_mode = "noop"
        destination = "local/prometheus.yml"
      }

      resources {
        cpu    = 200
        memory = 512
      }

      service {
        provider = "nomad"
        port     = "http"
        name     = "victoriametrics"
      }
    }
  }
}
