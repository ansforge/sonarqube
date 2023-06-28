project = "odrtest-forge-sonarqube"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    profile = "${workspace.name}"
    data_source "git" {
        url  = "https://github.com/ansforge/sonarqube.git"
        ref  = "var.datacenter"
        ignore_changes_outside_path = true
    }
    poll { # Pour redéployer le service si la branche est modifiée
        enabled = false
    }
}

################################
app "forge/sonarqube-db" {

    build {
        use "docker-ref" {
            image = var.image-db
            tag   = var.tag-db
        }
    }
  
    deploy{
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/sonarqube-db/forge-sonarqube-postgresql.nomad.tpl", {
                image   = var.image-db
                tag     = var.tag-db
                datacenter = var.datacenter
                nomad_namespace = var.nomad_namespace
            })
        }
    }
}

################################
app "forge/sonarqube-app" {

    build {
        use "docker-ref" {
            image = var.image-app
            tag   = var.tag-app
        }
    }
  
    deploy{
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/sonarqube-app/forge-sonarqube.nomad.tpl", {
                image   = var.image-app
                tag     = var.tag-app
                datacenter = var.datacenter
                qual_fqdn = var.qual_fqdn
                repo_url = var.repo_url
                nomad_namespace = var.nomad_namespace
            })
        }
    }
}





################################
variable "datacenter" {
    type    = string
    default = "henix_docker_platform_pfcpx"
}
variable "nomad_namespace" {
    type = string
    default = ""
    env = ["NOMAD_NAMESPACE"]
}
# Variable de l'application
variable "image-app" {
    type    = string
    default = "sonarqube"
}

variable "tag-app" {
    type    = string
    default = "9.9-developer"
}

variable "qual_fqdn" {
    type    = string
    default = "qual.forge.asipsante.fr"
}

variable "repo_url" {
    type    = string
    default = "http://repo.proxy-prod-forge.asip.hst.fluxus.net"
}

# Variable de la Base de donnée
variable "image-db" {
    type    = string
    default = "postgres"
}

variable "tag-db" {
    type    = string
    default = "15.2"
}