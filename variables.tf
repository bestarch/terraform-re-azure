variable "prefix" {
  description = "Prefix of the resources to be created"
  type        = string
  default     = "abhi"
}

variable "region" {
  description = "Geographical region where resources to be created"
  type        = string
  default     = "centralindia"
}

variable "vnet_cidr" {
  description = "VNET CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.2.0/24"
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_E4ads_v5"
}

variable "vm_sku" {
  description = "VM SKU"
  type        = string
  default     = "server"
}

variable "vm_publisher" {
  description = "VM publisher"
  type        = string
  default     = "Canonical"
}


variable "vm_type" {
  description = "VM type"
  type        = string
  default     = "ubuntu-24_04-lts"
}

variable "username" {
  description = "VM login username"
  type        = string
  default     = "abhishek"
}

variable "password" {
  description = "VM login password"
  type        = string
  default     = "Password1234@"
}

variable "cluster_name" {
  description = "Full name of Redis cluster such as mycluster.example.com"
  type        = string
  default     = "redis-poc.dlqueue.com"
}

variable "redis_user" {
  description = "User for redis node"
  type        = string
  default     = "redis-user"
}


variable "time_zone" {
  description = "Time zone"
  type        = string
  default     = "Asia/Kolkata"
}


variable "cluster_admin_username" {
  description = "username of the cluster admin like admin@example.com"
  type        = string
  default     = "admin@example.com"
}

variable "cluster_admin_password" {
  description = "Password of the cluster admin"
  type        = string
  sensitive = true
}

variable "vm_tag" {
  type = map(string)
  default = {
    environment = "staging"
    owner = "abhishek"
  }
}

variable "redis_tar_file" {
  description = "Redis tar file to download"
  type        = string
}

variable "create_cluster" {
  description = "Create Redis cluster"
  type        = bool
  default     = true
}

