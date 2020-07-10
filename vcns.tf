## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_virtual_network" "VCNRegion1" {
  provider       = oci.region1
  cidr_block     = var.VCNRegion1-CIDR
  dns_label      = "VCN1"
  compartment_id = var.compartment_ocid
  display_name   = "VCN1"
}

resource "oci_core_virtual_network" "VCNRegion2" {
  provider       = oci.region2
  cidr_block     = var.VCNRegion2-CIDR
  dns_label      = "VCN2"
  compartment_id = var.compartment_ocid
  display_name   = "VCN2"
}

resource "oci_core_virtual_network" "VCNRegion3" {
  provider       = oci.region3
  cidr_block     = var.VCNRegion3-CIDR
  dns_label      = "VCN3"
  compartment_id = var.compartment_ocid
  display_name   = "VCN3"
}

