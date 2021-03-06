variable "minecraft_server_url" {
  default = "https://launcher.mojang.com/v1/objects/0a269b5f2c5b93b1712d0f5dc43b6182b9ab254e/server.jar"
}

variable "ad_map" {
  description = "Associate an ad with an index number"
  type = map

  default = {
    ad1 = 0
    ad2 = 1
    ad3 = 2
  }

}

variable "minecraft_server_test_vm_source_image_id" {
  default = "ocid1.image.oc1.iad.aaaaaaaaijzevirp67bdceiebqeg4epuqstqcogohn3gskw76ngxupke3zfa"
}

variable "compartment_ocid" {}
variable "private_key_path" {}
variable "region" {}
variable "ad" {}
variable "ssh_authorized_keys" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "tenancy_ocid" {}
variable "private_key_password" {}
