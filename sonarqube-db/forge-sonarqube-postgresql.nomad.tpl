job "forge-sonarqube-postgresql" {
    datacenters = ["${datacenter}"]
    type = "service"
    vault {
        policies = ["forge"]
        change_mode = "restart"
    }
    group "sonarqube-postgresql" {
        count ="1"
        
        restart {
            attempts = 3
            delay = "60s"
            interval = "1h"
            mode = "fail"
        }
        
        constraint {
            attribute = "$\u007Bnode.class\u007D"
            value     = "data"
        }

        network {
            port "postgres" { to = 5432 }
        }
        
        task "postgres" {
            driver = "docker"

            # log-shipper
            leader = true 

            template {
                data = <<EOH

{{ with secret "forge/sonarqube" }}
POSTGRES_DB = {{ .Data.data.db_name }}
POSTGRES_USER={{ .Data.data.psql_username }}
POSTGRES_PASSWORD={{ .Data.data.psql_password }}
{{ end }}

                EOH
                destination = "secrets/file.env"
                change_mode = "restart"
                env = true
            }

            config {
                image   = "${image}:${tag}"
                ports   = ["postgres"]
                volumes = ["name=forge-sonarqube-db,io_priority=high,size=25,repl=2:/var/lib/postgresql/data"]
                volume_driver = "pxd"
            }
            
            resources {
                cpu    = 500
                memory = 1024
            }
            
            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                port = "postgres"
                tags = ["urlprefix-:5432 proto=tcp"]
                check {
                    name     = "alive"
                    type     = "tcp"
                    interval = "30s"
                    timeout  = "5s"
                    port     = "postgres"
                }
            }
        }

        # log-shipper
        task "log-shipper" {
            driver = "docker"
            restart {
                    interval = "3m"
                    attempts = 5
                    delay    = "15s"
                    mode     = "delay"
            }
            meta {
                INSTANCE = "$\u007BNOMAD_ALLOC_NAME\u007D"
            }
            template {
                data = <<EOH
REDIS_HOSTS = {{ range service "PileELK-redis" }}{{ .Address }}:{{ .Port }}{{ end }}
PILE_ELK_APPLICATION = SONARQUBE 
EOH
                destination = "local/file.env"
                change_mode = "restart"
                env = true
            }
            config {
                image = "ans/nomad-filebeat:8.2.3-2.0"
            }
            resources {
                cpu    = 100
                memory = 150
            }
        } #end log-shipper 

    }
}
