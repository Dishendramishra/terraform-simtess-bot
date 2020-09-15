terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  version = "3.5.0"

  credentials = file("cloud_access_key.json")

  project = "<ID>"
  region  = "us-central1"
  zone    = "us-central1-c"
}

# resource "google_compute_address" "static" {
#   name = "ipv4-address"
# }

data "template_file" "user_data" {
  template = file("scripts/add-ssh-web-app.yaml")
}


resource "google_compute_instance" "vm_instance" {
  metadata = {
    user-data = data.template_file.user_data.rendered
  }

  name         = "terraform-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # nat_ip = google_compute_address.static.address
    }
  }

  tags = ["http-server"]
}

resource "google_compute_firewall" "http-server" {
  name    = "default-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80","22"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

