## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_security_list" "SecurityListSQLNetRegion2" {
  provider       = oci.region2
  compartment_id = var.compartment_ocid
  display_name   = "SecurityListSQLNetRegion2"
  vcn_id         = oci_core_virtual_network.VCNRegion2.id

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.SubnetRegion1-CIDR
    tcp_options {
      max = 1521
      min = 1521
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.SubnetRegion2-CIDR
    tcp_options {
      max = 1521
      min = 1521
    }
  }
  
  ingress_security_rules {
    protocol = "6"
    source   = var.SubnetRegion3-CIDR
    tcp_options {
      max = 1521
      min = 1521
    }
  }
}

resource "oci_core_security_list" "SecurityListSSHRegion2" {
  provider       = oci.region2
  compartment_id = var.compartment_ocid
  display_name   = "SecurityListSSHRegion2"
  vcn_id         = oci_core_virtual_network.VCNRegion2.id

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.SubnetRegion1-CIDR
    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.SubnetRegion3-CIDR
    tcp_options {
      max = 22
      min = 22
    }
  }

}