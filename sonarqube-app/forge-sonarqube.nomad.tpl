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
            # Ajout de plugins
            artifact {
                source = "https://repo.forge.ans.henix.fr:443/artifactory/ext-tools/qualimetrie/sonarqube-plugins/sonar-dependency-check-plugin-3.0.1.jar"
                options {
		            archive = false
  		        }
		    }
            artifact {
                source = "https://repo.forge.ans.henix.fr:443/artifactory/ext-tools/qualimetrie/sonarqube-plugins/checkstyle-sonar-plugin-10.8.1.jar"
                options {
		            archive = false
  		        }
		    }
            artifact {
                source = "https://repo.forge.ans.henix.fr:443/artifactory/ext-tools/qualimetrie/sonarqube-plugins/sonar-findbugs-plugin-4.2.3.jar"
                options {
		            archive = false
  		        }
		    }
            artifact {
	    	    source = "https://repo.forge.ans.henix.fr:443/artifactory/ext-tools/qualimetrie/sonarqube-plugins/sonar-groovy-plugin-1.8.jar"
                options {
		            archive = false
  		        }
		    }
            artifact {
	    	    source = "https://repo.forge.ans.henix.fr:443/artifactory/ext-tools/qualimetrie/sonarqube-plugins/sonar-pmd-plugin-3.4.0.jar"
                options {
		            archive = false
  		        }
		    }
            #Ajout du Certificat
            artifact { 
	    	    source = "https://repo.forge.ans.henix.fr:443/artifactory/asip-ac/truststore/cacerts"
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
LDAP_URL=ldap://{{ range service "ldap-forge" }}{{ .Address }}{{ end }}
LDAP_BINDPASSWORD={{ with secret "forge/sonarqube" }}{{ .Data.data.ldap_password }}{{ end }}
SONAR_SECURITY_REALM=LDAP
SONAR_SECURITY_SAVEPASSWORD=true
LDAP_BINDDN=cn=Manager,dc=asipsante,dc=fr
# User Configuration
LDAP_USER_BASEDN=ou=People,dc=asipsante,dc=fr
LDAP_USER_REQUEST=(&(objectClass=inetOrgPerson)(uid={login}))
LDAP_USER_REALNAMEATTRIBUTE=cn
LDAP_USER_EMAILATTRIBUTE=mail
# Group Configuration
LDAP_GROUP_BASEDN=ou=group,dc=asipsante,dc=fr
LDAP_GROUP_REQUEST=(&(objectClass=posixGroup)(memberUid={uid}))
                EOH
                destination = "secrets/file.env"
                change_mode = "restart"
                env = true
            }

            config {
                image   = "${image}:${tag}"
                ports   = ["http"]

                extra_hosts = ["sonar.db.internal:$\u007BNOMAD_IP_http\u007D"]
                
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
                # Certificat    
                mount {
                    type = "bind"
                    target = "/opt/java/openjdk/lib/security/cacerts"
                    source = "local/cacerts"
                    readonly = true
                    bind_options {
                        propagation = "rshared"
                    }
                } 
                # token    
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
                cpu    = 600
                memory = 6144
            }
            
            service {
                name = "$\u007BNOMAD_JOB_NAME\u007D"
                tags = ["urlprefix-qual.forge.asipsante.fr/"]
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
    }
}