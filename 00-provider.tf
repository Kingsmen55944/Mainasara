terraform {
  # Remote state in S3
  backend "s3" {
    bucket       = "mainasara-0920"
    key          = "k3s/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true

    # Backend authentication
    access_key = "YOUR_ACCESS_KEY"
    secret_key = "YOUR_SECRET_KEY"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

# ---- k3s cluster access for Helm and Kubernetes, read from the kubeconfig stored in S3 ----
data "aws_s3_object" "kubeconfig" {
  bucket     = var.s3_bucket
  key        = aws_s3_object.kubeconfig.key
  depends_on = [aws_s3_object.kubeconfig]
}

locals {
  kubeconfig = yamldecode(data.aws_s3_object.kubeconfig.body)
}

provider "helm" {
  kubernetes = {
    host                   = local.kubeconfig.clusters[0].cluster.server
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
    client_certificate     = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig.users[0].user["client-key-data"])
  }
}

provider "kubernetes" {
  host                   = local.kubeconfig.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig.users[0].user["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig.users[0].user["client-key-data"])
}

# Configure the AWS Provider.

provider "aws" {
  region     = "eu-north-1"
  access_key = "YOUR_ACCESS_KEY"
  secret_key = "YOUR_SECRET_KEY"
}
