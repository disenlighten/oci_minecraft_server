terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
    }
  }
}


data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_instance" "minecraft_server_test_vm" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.this.availability_domains[lookup(var.ad_map, var.ad, 0)],"name")}"
  compartment_id      = var.compartment_ocid
  create_vnic_details {
    assign_public_ip = "true"
    display_name     = "minecraft_server_test_vm"
    freeform_tags = {
    }

    nsg_ids = [
    ]
    skip_source_dest_check = "false"
    subnet_id              = oci_core_subnet.main_subnet.id
  }

  display_name = "minecraft_server_test_vm"

  instance_options {
    are_legacy_imds_endpoints_disabled = "false"
  }

  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = "true"
    is_pv_encryption_in_transit_enabled = "true"
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }
  metadata = {
    "ssh_authorized_keys" = var.ssh_authorized_keys
  }

  shape = "VM.Standard.A1.Flex"
  shape_config {
    baseline_ocpu_utilization = ""
    memory_in_gbs             = "6"
    ocpus                     = "2"
  }
  source_details {
    source_id   = var.minecraft_server_test_vm_source_image_id
    source_type = "image"
  }

  connection {
    type  = "ssh"
    user  = "opc"
    host  = self.public_ip
    agent = true
  }

  provisioner "file" {
    source      = "./files/configure_server.yml"
    destination = "configure_server.yml"
  }

  provisioner "file" {
    source      = "./files/minecraft.service"
    destination = "minecraft.service"
  }

    provisioner "file" {
    source      = "./files/service.sh"
    destination = "service.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y ansible --enablerepo ol7_developer --enablerepo ol7_developer_EPEL --enablerepo ol7_oci_included",
      "ansible-playbook configure_server.yml -e \"MINECRAFT_SERVER_URL=${var.minecraft_server_url}\" -b",
    ]
  }
  state = "RUNNING"
}

resource "oci_core_internet_gateway" "Internet-Gateway-main_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "Internet Gateway main_vcn"
  enabled        = "true"
  freeform_tags = {
  }
  vcn_id = oci_core_vcn.main_vcn.id
}

resource "oci_core_subnet" "main_subnet" {
  cidr_block      = "10.0.0.0/24"
  compartment_id  = var.compartment_ocid
  dhcp_options_id = oci_core_vcn.main_vcn.default_dhcp_options_id
  display_name    = "main_subnet"
  freeform_tags = {
  }
  prohibit_internet_ingress  = "false"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_vcn.main_vcn.default_route_table_id
  security_list_ids = [
    oci_core_vcn.main_vcn.default_security_list_id,
  ]
  vcn_id = oci_core_vcn.main_vcn.id
}

resource "oci_core_vcn" "main_vcn" {
  cidr_blocks = [
    "10.0.0.0/16",
  ]
  compartment_id = var.compartment_ocid
  display_name   = "main_vcn"
  freeform_tags = {
  }
}

resource "oci_core_default_dhcp_options" "Default-DHCP-Options-for-main_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "Default DHCP Options for main_vcn"
  freeform_tags = {
  }
  manage_default_resource_id = oci_core_vcn.main_vcn.default_dhcp_options_id
  options {
    custom_dns_servers = [
    ]
    server_type = "VcnLocalPlusInternet"
    type        = "DomainNameServer"
  }
}

resource "oci_core_default_route_table" "Default-Route-Table-for-main_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "Default Route Table for main_vcn"
  freeform_tags = {
  }
  manage_default_resource_id = oci_core_vcn.main_vcn.default_route_table_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.Internet-Gateway-main_vcn.id
  }
}

resource "oci_core_default_security_list" "Default-Security-List-for-main_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "Default Security List for main_vcn"
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  freeform_tags = {
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Opening TCP traffic for Minecraft server"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "25565"
      min = "25565"
    }
  }
  ingress_security_rules {
    description = "Opening UDP traffic for Minecraft server"
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    udp_options {
      max = "25565"
      min = "25565"
    }
  }
  manage_default_resource_id = oci_core_vcn.main_vcn.default_security_list_id
}

