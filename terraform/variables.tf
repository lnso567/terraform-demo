variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-northeast1-a"
}

variable "app_machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "monitor_machine_type" {
  type    = string
  default = "e2-standard-4"
}
