project = "forge/sonarqube-db"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    data_source "git" {
        url  = "https://github.com/ansforge/sonarqube.git"
        ref  = "var.datacenter"
        path = "sonarqube-db"
        ignore_changes_outside_path = true
    }
}

app "forge/sonarqube-db" {

    build {
        use "docker-pull" {
            image = var.image
            tag   = var.tag
            disable_entrypoint = true
        }
    }
  
    deploy{
        use "nomad-jobspec" {
            jobspec = templatefile("${path.app}/forge-sonarqube-postgresql.nomad.tpl", {
            image   = var.image
            tag     = var.tag
            datacenter = var.datacenter
            })
        }
    }
}

variable "datacenter" {
    type    = string
    default = "henix_docker_platform_dev"
}

variable "image" {
    type    = string
    default = "postgres"
}

variable "tag" {
    type    = string
    default = "15.2"
}