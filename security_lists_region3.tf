## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_security_list" "SecurityListSSHRegion3" {
  provider       = oci.region3
  compartment_id = var.compartment_ocid
  display_name   = "SecurityListSSHRegion3"
  vcn_id         = oci_core_virtual_network.VCNRegion3.id

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      max = 22
      min = 22
    }
  }
}