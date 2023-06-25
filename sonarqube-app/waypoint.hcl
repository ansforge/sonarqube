project = "forge/sonarqube"

labels = { "domaine" = "forge" }

runner {
    enabled = true
    profile = "${workspace.name}"
    data_source "git" {
        url  = "https://rhodecode.proxy.dev.forge.esante.gouv.fr/SandBox/QM/FORGE/Sonarqube.git"
        ref  = "var.datacenter"
        path = "sonarqube-app"
        ignore_changes_outside_path = true
    }
}

app "forge/sonarqube-app" {

    build {
        use "docker-ref" {
            image = var.image
            tag   = var.tag
            # disable_entrypoint = false
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

variable datacenter {
    type = string
    default = "henix_docker_platform_pfcpx"
    env = ["NOMAD_DATACENTER"]
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
    default = "qual.forge.henix.asipsante.fr"
}

variable "repo_url" {
    type    = string
    default = "http://repo.proxy-dev-forge.asip.hst.fluxus.net"
}
