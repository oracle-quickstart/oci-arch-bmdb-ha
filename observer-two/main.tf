# ---- use variables defined in terraform.tfvars file
variable "tenancy_ocid"            {}
variable "user_ocid"               {}
variable "fingerprint"             {}
variable "private_key_path"        {}
variable "compartment_ocid"        {}
variable "region"                  {}
variable "AD"                      {}
variable "BootStrapFile_ol7"       {}
variable "ssh_public_key_file_ol7" {}
variable "authorized_ips"          {}


# ---- provider
provider "oci" {
  region           = "${var.region}"
  tenancy_ocid     = "${var.tenancy_ocid}"
  user_ocid        = "${var.user_ocid}"
  fingerprint      = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
}


# -------- get the list of available ADs
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

# ------ Create a new VCN
variable "VCN-CIDR" { default = "10.0.0.0/16" }

resource "oci_core_virtual_network" "observer-two-vcn" {
  cidr_block = "${var.VCN-CIDR}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "observer-two-vcn"
  dns_label = "ovavcn"

}

# ------ Create a new Internet Gategay
resource "oci_core_internet_gateway" "observer-two-ig" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "observer-two-internet-gateway"
    vcn_id = "${oci_core_virtual_network.observer-two-vcn.id}"
}

# ------ Create a new Route Table
resource "oci_core_route_table" "observer-two-rt" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.observer-two-vcn.id}"
    display_name = "observer-two-route-table"
    route_rules {
        cidr_block = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.observer-two-ig.id}"
    }
}

# ------ Create a new security list to be used in the new subnet
resource "oci_core_security_list" "observer-two-subnet1-sl" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "observer-two-subnet1-security-list"
    vcn_id = "${oci_core_virtual_network.observer-two-vcn.id}"
    egress_security_rules = [{
	protocol = "all" 
	destination = "0.0.0.0/0"
    }]

    ingress_security_rules = [{
        protocol = "6"  # tcp
        source = "${var.VCN-CIDR}"
    },
    {
        protocol = "6"  # tcp
        source = "0.0.0.0/0"
        source = "${var.authorized_ips}"
        tcp_options {
          "min" = 22
          "max" = 22
        }
        
    }]
}

# ------ Create a public subnet 1 in AD1 in the new VCN
resource "oci_core_subnet" "observer-two-public-subnet1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  cidr_block = "10.0.1.0/24"
  display_name = "observer-two-public-subnet1"
  dns_label = "subnet1"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.observer-two-vcn.id}"
  route_table_id = "${oci_core_route_table.observer-two-rt.id}"
  security_list_ids = ["${oci_core_security_list.observer-two-subnet1-sl.id}"]
  dhcp_options_id = "${oci_core_virtual_network.observer-two-vcn.default_dhcp_options_id}"
}


# --------- Get the OCID for the more recent for Oracle Linux 7.4 disk image
data "oci_core_images" "OLImageOCID-ol7" {
    compartment_id = "${var.compartment_ocid}"
    operating_system = "Oracle Linux"
    operating_system_version = "7.4"
}

# ------ Create a compute instance from the more recent Oracle Linux 7.4 image
resource "oci_core_instance" "observer-two" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}" 
  compartment_id = "${var.compartment_ocid}"
  display_name = "observer-two"
  hostname_label = "observer-two"
  #image = "${lookup(data.oci_core_images.OLImageOCID-ol7.images[0], "id")}"
  image = "ocid1.image.oc1.phx.aaaaaaaaoqj42sokaoh42l76wsyhn3k2beuntrh5maj3gmgmzeyr55zzrwwa"
  shape = "VM.Standard1.1"
  subnet_id = "${oci_core_subnet.observer-two-public-subnet1.id}"
  metadata {
    ssh_authorized_keys = "${file(var.ssh_public_key_file_ol7)}"
    user_data = "${base64encode(file(var.BootStrapFile_ol7))}"
  }

  timeouts {
    create = "30m"
  }
}

# ------ Get the public IP of instance and display it on screen
output "InstancePublicIP-ol7" {
  value = ["${oci_core_instance.observer-two.public_ip}"]
}


# ------ Get the private IP of instance and display it on screen
output "InstancePublicDNS-ol7" {
  value = ["${oci_core_instance.observer-two.private_ip}"]
}



