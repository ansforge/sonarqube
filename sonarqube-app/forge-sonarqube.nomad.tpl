job "forge-sonarqube" {
    datacenters = ["${datacenter}"]
    type = "service"

    vault {
        policies = ["forge"]
        change_mode = "restart"
    }

    group "sonarqube" {
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
            port "http" {
                to = 9000
            }
        }

        task "sonarqube" {
            driver = "docker"

            # log-shipper
            leader = true 

            # Ajout de plugins
            artifact {
                source = "${repo_url}/artifactory/ext-tools/qualimetrie/sonarqube-plugins/sonar-dependency-check-plugin-3.0.1.jar"
                options {
                    archive = false
                }
            }
            artifact {
                source = "${repo_url}/artifactory/ext-tools/qualimetrie/sonarqube-plugins/checkstyle-sonar-plugin-10.8.1.jar"
                options {
                    archive = false
                }
            }
            artifact {
                source = "${repo_url}/artifactory/ext-tools/qualimetrie/sonarqube-plugins/sonar-findbugs-plugin-4.2.3.jar"
                options {
                    archive = false
                }
            }
            artifact {
                source = "${repo_url}/artifactory/ext-tools/qualimetrie/sonarqube-plugins/sonar-groovy-plugin-1.8.jar"
                options {
                    archive = false
                }
            }
            artifact {
                source = "${repo_url}/artifactory/ext-tools/qualimetrie/sonarqube-plugins/sonar-pmd-plugin-3.4.0.jar"
                options {
                    archive = false
                }
            }
            # Trustore java
            artifact { 
                source = "${repo_url}/artifactory/asip-ac/truststore/cacerts"
                options {
                    archive = false
                }
            }

            template {
                data = <<EOH
{{ with secret "forge/sonarqube" }}
{{ .Data.data.token_sonar }}
{{ end }}
                EOH
                destination = "secrets/sonar-secret.txt"
                change_mode = "restart"
            }

            template {
                data = <<EOH
# SonarQube Configuration
SONAR_WEB_CONTEXT=/sonar
SONAR_UPDATECENTER_ACTIVATE=false
SONAR_SECRETKEYPATH=/opt/sonarqube/.sonar/sonar-secret.txt
# JDBC Configuration
SONAR_JDBC_USERNAME={{ with secret "forge/sonarqube" }}{{ .Data.data.psql_username }}{{ end }}
SONAR_JDBC_PASSWORD={{ with secret "forge/sonarqube" }}{{ .Data.data.psql_password }}{{ end }}
SONAR_JDBC_URL=jdbc:postgresql://sonar.db.internal:5432/sonar?currentSchema={{ with secret "forge/sonarqube" }}{{ .Data.data.db_name }}{{ end }}
# LDAP Configuration
LDAP_URL=ldap://{{ range service "openldap-forge" }}{{ .Address }}{{ end }}
LDAP_BINDPASSWORD={{ with secret "forge/openldap" }}{{ .Data.data.admin_password }}{{ end }}
SONAR_SECURITY_REALM=LDAP
SONAR_SECURITY_SAVEPASSWORD=true
LDAP_BINDDN=cn=Manager,{{ with secret "forge/openldap" }}{{ .Data.data.ldap_root }}{{ end }}
# User Configuration
LDAP_USER_BASEDN=ou=People,{{ with secret "forge/openldap" }}{{ .Data.data.ldap_root }}{{ end }}
LDAP_USER_REQUEST=(&(objectClass=inetOrgPerson)(uid={login}))
LDAP_USER_REALNAMEATTRIBUTE=cn
LDAP_USER_EMAILATTRIBUTE=mail
# Group Configuration
LDAP_GROUP_BASEDN=ou=group,{{ with secret "forge/openldap" }}{{ .Data.data.ldap_root }}{{ end }}
LDAP_GROUP_REQUEST=(&(objectClass=posixGroup)(memberUid={uid}))
                EOH
                destination = "secrets/file.env"
                change_mode = "restart"
                env = true
            }

            config {
                image   = "${image}:${tag}"
                ports   = ["http"]

                extra_hosts = [
                               "sonar.db.internal:$\u007BNOMAD_IP_http\u007D",
                               "gitlab.internal jenkins.internal:$\u007Battr.unique.network.ip-address\u007D"
                              ]

                mount {
                    type = "volume"
                    target = "/opt/sonarqube/data/"
                    source = "sonarqube_data"
                    readonly = false
                    volume_options {
                        no_copy = false
                        driver_config {
                            name = "pxd"
                            options {
                                io_priority = "high"
                                size = 2
                                repl = 1
                            }
                        }
                    }
                }

                # Mise en place des plugins
                mount {
                    type = "bind"
                    target = "/opt/sonarqube/extensions/plugins/sonar-dependency-check-plugin-3.0.1.jar"
                    source = "local/sonar-dependency-check-plugin-3.0.1.jar"
                    bind_options {
                        propagation = "rshared"
                    }
                } 
                mount {
                    type = "bind"
                    target = "/opt/sonarqube/extensions/plugins/checkstyle-sonar-plugin-10.8.1.jar"
                    source = "local/checkstyle-sonar-plugin-10.8.1.jar"
                    bind_options {
                        propagation = "rshared"
                    }
                }
                mount {
                    type = "bind"
                    target = "/opt/sonarqube/extensions/plugins/sonar-findbugs-plugin-4.2.3.jar"
                    source = "local/sonar-findbugs-plugin-4.2.3.jar"
                    bind_options {
                        propagation = "rshared"
                    }
                }
                mount {
                    type = "bind"
                    target = "/opt/sonarqube/extensions/plugins/sonar-groovy-plugin-1.8.jar"
                    source = "local/sonar-groovy-plugin-1.8.jar"
                    bind_options {
                        propagation = "rshared"
                    }
                } 
                mount {
                    type = "bind"
                    target = "/opt/sonarqube/extensions/plugins/sonar-pmd-plugin-3.4.0.jar"
                    source = "local/sonar-pmd-plugin-3.4.0.jar"
                    bind_options {
                        propagation = "rshared"
                    }
                }
                # Surcharge du trustore java
                mount {
                    type = "bind"
                    target = "/opt/java/openjdk/lib/security/cacerts"
                    source = "local/cacerts"
                    readonly = true
                    bind_options {
                        propagation = "rshared"
                    }
                }
                # token sonar
                mount {
                    type = "bind"
                    target = "/opt/sonarqube/.sonar/sonar-secret.txt"
                    source = "secrets/sonar-secret.txt"
                    readonly = true
                    bind_options {
                        propagation = "rshared"
                    }
                }
            }

            resources {
                cpu    = 2048
                memory = 6144
            }

            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                tags = [
                        "urlprefix-${qual_fqdn}/",
                        "urlprefix-${qual_fqdn_vip}/",
                        "urlprefix-qual.internal/"
                        ]
                port = "http"
                check {
                    name     = "alive"
                    type     = "http"
                    path     = "/sonar"
                    interval = "30s"
                    timeout  = "5s"
                    port     = "http"
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
