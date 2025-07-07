# nginx-ami.pkr.hcl

# Define the required Packer plugin — in this case, for building AMIs on AWS
packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

# Set the AWS region (can be overridden via CLI)
variable "region" {
  default = "us-east-2"
}

# Define the AWS AMI build source using the amazon-ebs builder
source "amazon-ebs" "nginx" {
  # Use the region defined above
  region = var.region

  # Choose a base Ubuntu image using filters
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"] # Canonical (official Ubuntu publisher)
    most_recent = true             # Always get the latest matching image
  }

  # Use a small instance type for building the AMI
  instance_type = "t2.micro"

  # SSH username for Ubuntu
  ssh_username = "ubuntu"

  # Name the resulting AMI with a timestamp to avoid name conflicts
  ami_name = "packer-nginx-{{timestamp}}"
}

# The build block ties everything together
build {
  sources = ["source.amazon-ebs.nginx"]

  # Provisioning commands to run on the temporary instance
  provisioner "shell" {
    inline = [
      "sudo apt-get update",              # Update package lists
      "sudo apt-get install -y nginx",    # Install NGINX
      "sudo systemctl enable nginx"       # Enable NGINX to start on boot
    ]
  }
}
