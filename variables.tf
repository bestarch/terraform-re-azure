variable "prefix" {
  description = "Prefix of the resources to be created"
  type        = string
  default     = "abhi"
}

variable "create_dr_cluster" {
  description = "Create DR cluster or not. Default is false"
  type        = bool
  default     = false
}

variable "create_test_vm" {
  description = "Create A test VM to test the Redis database. Default is false"
  type        = bool
  default     = false
}

variable "test_vnet_cidr" {
  description = "VNET CIDR block for test VM"
  type        = string
  default     = "10.2.0.0/16"
}

variable "test_vm_size" {
  description = "Size of test VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "test_vm_sku" {
  description = "Test VM SKU"
  type        = string
  default     = "95_gen2"
}

variable "test_vm_publisher" {
  description = "Test VM publisher"
  type        = string
  default     = "RedHat"
}

variable "test_vm_type" {
  description = "Test VM type"
  type        = string
  default     = "RHEL"
}

variable "primary_region" {
  description = "Geographical region where resources to be created"
  type        = string
  default     = "centralindia"
}

variable "dr_region" {
  description = "Geographical region where DR resources to be created"
  type        = string
  default     = "southeastasia"
}

variable "vnet_cidr" {
  description = "VNET CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vnet_cidr_dr" {
  description = "VNET CIDR block for DR"
  type        = string
  default     = "10.1.0.0/16"
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

variable "vm_size_dr" {
  description = "VM size of DR"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "vm_sku_dr" {
  description = "VM SKU"
  type        = string
  default     = "server"
}

variable "vm_publisher_dr" {
  description = "VM publisher"
  type        = string
  default     = "Canonical"
}

variable "vm_type_dr" {
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

variable "cluster_name_dr" {
  description = "Full name of Redis DR cluster such as mycluster-dr.example.com"
  type        = string
  default     = "redis-poc-dr.dlqueue.com"
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

variable "node_count_primary" {
  description = "Number of nodes in primary cluster"
  type        = number
}

variable "node_count_dr" {
  description = "Number of nodes in DR cluster"
  type        = number
}

variable "vm_tag" {
  type = map(string)
  default = {
    environment = "staging"
    owner = "abhishek"
  }
}

variable "redis_tar_file_location" {
  description = "Redis tar file to download"
  type        = string
}

variable "ip_names" {
  description = "Public IP addresses that needs to be associated to Redis nodes"
  type = list(string)
}

variable "ip_names_dr" {
  description = "Public IP addresses that needs to be associated to Redis node in DR"
  type = list(string)
}

variable "resource_grp_containing_pips" {
  description = "Resource group which contains public IP addresses"
  type        = string
}

