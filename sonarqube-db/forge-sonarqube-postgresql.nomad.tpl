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
                cpu    = 600
                memory = 2048
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
    }
}