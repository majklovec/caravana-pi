job "[[.DEPLOY_HOST]]" {
  datacenters = [[ .DATACENTERS  | toJson ]]
  type        = "service"

  // must have linux for network mode
  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }


  group "[[.SERVICE_ID]]" {
    count = 1

    network {
      port "http" { static = 3000 }
    }

    service {
      name     = "grafana"
      provider = "nomad"
      port     = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.[[.SERVICE_ID]].rule=Host(`[[.DOMAIN]]`)"
      ]
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:[[ .VERSION ]]"
        ports = ["http"]
        mount {
          type     = "bind"
          target   = "/var/lib/grafana"
          source   = "/data/[[.SERVICE_ID]]"
          readonly = false
        }
      }

      env {
        [[- range $key, $value := .ENV_VARS ]]
        [[ $key ]] = [[ $value | quote]]
        [[- end ]]
      }

      [[- if .ARTIFACTS ]]
      [[- range $artifact := .ARTIFACTS ]]
      artifact {
        source      = [[ $artifact.source | quote ]]
        destination = [[ $artifact.destination | quote ]]
        mode        = [[ $artifact.mode | quote ]]
        [[- if $artifact.options ]]
        options {
          [[- range $option, $val := $artifact.options ]]
          [[ $option ]] = [[ $val | quote ]]
          [[- end ]]
        }
        [[- end ]]

      }
      [[- end ]]
      [[- end ]]

      template {
        data        = <<EOF
[[ .GRAFANAINI ]]
EOF
        destination = "/local/grafana/grafana.ini"
      }

      [[- if .DASHBOARDS ]]
      template {
        data        = <<EOF
[[ .DASHBOARDS ]]
EOF
        destination = "/local/grafana/provisioning/dashboards/dashboards.yaml"
      }
      [[- end ]]

      [[- if .DATASOURCES ]]
      template {
        data        = <<EOF
[[ .DATASOURCES ]]
EOF
        destination = "/local/grafana/provisioning/datasources/datasources.yaml"
      }
      [[- end ]]

      [[- if .PLUGINS ]]

      template {
        data        = <<EOF
[[ .PLUGINS ]]
EOF
        destination = "/local/grafana/provisioning/plugins/plugins.yml"
      }
      [[- end ]]
    }
  }
}
