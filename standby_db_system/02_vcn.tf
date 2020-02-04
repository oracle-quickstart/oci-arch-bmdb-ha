# -------- get the list of available ADs
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

# ------ Create a new VCN
variable "VCN-CIDR" { default = "10.0.0.0/16" }

resource "oci_core_virtual_network" "standby-vcn" {
  cidr_block = "${var.VCN-CIDR}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "standby-vcn"
  dns_label = "ovavcn"

}

# ------ Create a new Internet Gategay
resource "oci_core_internet_gateway" "standby-ig" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "standby-internet-gateway"
    vcn_id = "${oci_core_virtual_network.standby-vcn.id}"
}

# ------ Create a new Route Table
resource "oci_core_route_table" "standby-rt" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.standby-vcn.id}"
    display_name = "standby-route-table"
    route_rules {
        cidr_block = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.standby-ig.id}"
    }
}

# ------ Create a new security list to be used in the new subnet
resource "oci_core_security_list" "standby-subnet1-sl" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "standby-subnet1-security-list"
    vcn_id = "${oci_core_virtual_network.standby-vcn.id}"
    egress_security_rules = [{
	protocol = "all"
	destination = "0.0.0.0/0"
    }]

    ingress_security_rules = [{
        protocol = "all"
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
        
    },
    {
        protocol = "6"  # tcp
        source = "0.0.0.0/0"
        source = "${var.authorized_ips}"
        tcp_options {
          "min" = 1521
          "max" = 1521
        }
        
    }]
}

# ------ Create a public subnet 1 in the new VCN
resource "oci_core_subnet" "standby-public-subnet1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  cidr_block = "10.0.1.0/24"
  display_name = "standby-public-subnet1"
  dns_label = "subnet1"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.standby-vcn.id}"
  route_table_id = "${oci_core_route_table.standby-rt.id}"
  security_list_ids = ["${oci_core_security_list.standby-subnet1-sl.id}"]
  dhcp_options_id = "${oci_core_virtual_network.standby-vcn.default_dhcp_options_id}"
}


