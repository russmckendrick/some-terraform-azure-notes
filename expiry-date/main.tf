terraform {
  required_version = ">= 1.0.0"
  required_providers {
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "time" {
}

resource "time_rotating" "token" {
  rotation_days = 30
}
