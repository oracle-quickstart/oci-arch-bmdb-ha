## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_nat_gateway" "NATGatewayRegion1" {
  provider       = oci.region1
  compartment_id = var.compartment_ocid
  display_name   = "NATGatewayRegion1"
  vcn_id         = oci_core_virtual_network.VCNRegion1.id
}

resource "oci_core_nat_gateway" "NATGatewayRegion2" {
  provider       = oci.region2
  compartment_id = var.compartment_ocid
  display_name   = "NATGatewayRegion2"
  vcn_id         = oci_core_virtual_network.VCNRegion2.id
}
