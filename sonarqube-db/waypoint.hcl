project = "forge/sonarqube-db"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    profile = "${workspace.name}"
    data_source "git" {
        url  = "https://rhodecode.proxy.dev.forge.esante.gouv.fr/SandBox/QM/FORGE/Sonarqube.git"
        ref  = "var.datacenter"
        path = "sonarqube-db"
        ignore_changes_outside_path = true
    }
}

app "forge/sonarqube-db" {

    build {
        use "docker-ref" {
            image = var.image
            tag   = var.tag
            # disable_entrypoint = false
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

variable datacenter {
    type = string
    default = "henix_docker_platform_pfcpx"
    env = ["NOMAD_DATACENTER"]
}

variable "image" {
    type    = string
    default = "postgres"
}

variable "tag" {
    type    = string
    default = "15.2"
}