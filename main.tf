# Configure the Google Cloud provider
provider "google" {
  credentials                 = file("E:/GCPprivatekey/my-test-project-66944-21fbdf16fc2b.json") # Path to the service account JSON key file
  project                     = "my-test-project-66944"                                          # Google Cloud project ID
  region                      = "us-central1"
  zone                        = "us-central1-a" # Region where resources will be created
  impersonate_service_account = "terraform-service-account@my-test-project-66944.iam.gserviceaccount.com"

}

# Define a Google Compute Engine instance
resource "google_compute_instance" "vm_instance" {
  name         = "my-vm-instance" # Name of the VM instance
  machine_type = "e2-medium"      # Machine type (size) of the VM
  # zone         = "us-central1-a"  # Zone where the VM will be created

  # Configure the boot disk for the VM
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" # Base image for the VM (Debian 11)
    }
  }
  # Service account with specific access scopes
  service_account {
    email = "terraform-service-account@my-test-project-66944.iam.gserviceaccount.com" # Service account email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",      # Full access to all Google Cloud services
      "https://www.googleapis.com/auth/compute",             # Access to compute engine
      "https://www.googleapis.com/auth/devstorage.read_only" # Read-only access to Google Cloud Storage
    ]
  }


  # Configure the network interface for the VM
  network_interface {
    network = "default" # Use the default network
    access_config {     # Assign an external IP address to the VM
    }
  }

  tags = ["http-server"] # Tags to identify the VM for firewall rules

  # Metadata startup script to install and start Apache web server
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update  # Update package lists
    apt-get install -y apache2  # Install Apache web server
    systemctl start apache2  # Start Apache service
    systemctl enable apache2  # Enable Apache to start on boot
    sudo apt update
    sudo apt install -y docker.io
  EOT
}

# Define a firewall rule to allow HTTP traffic
resource "google_compute_firewall" "default" {
  name    = "default-allow-http" # Name of the firewall rule
  network = "default"            # Apply the rule to the default network

  # Allow incoming TCP traffic on port 80 (HTTP)
  allow {
    protocol = "tcp"
    ports    = ["80"] # Allow traffic on port 80
  }

  source_ranges = ["0.0.0.0/0"]   # Allow traffic from any IP address
  target_tags   = ["http-server"] # Apply this rule to instances with the tag "http-server"
}
