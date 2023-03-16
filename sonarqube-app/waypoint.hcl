project = "forge/sonarqube"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    data_source "git" {
        url  = "https://github.com/ansforge/sonarqube.git"
        ref  = "var.datacenter"
        path = "sonarqube-app"
        ignore_changes_outside_path = true
    }
}

app "forge/sonarqube-app" {

    build {
        use "docker-pull" {
            image = var.image
            tag   = var.tag
            disable_entrypoint = true
        }
    }
  
    deploy{
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/forge-sonarqube.nomad.tpl", {
            image   = var.image
            tag     = var.tag
            datacenter = var.datacenter
            qual_fqdn = var.qual_fqdn
            repo_url = var.repo_url
            })
        }
    }
}

variable "datacenter" {
    type    = string
    default = "test"
}

variable "image" {
    type    = string
    default = "sonarqube"
}

variable "tag" {
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
