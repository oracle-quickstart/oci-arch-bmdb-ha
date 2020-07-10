## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_drg" "DRGRegion1" {
  provider       = oci.region1
  display_name   = "DRGRegion1"
  compartment_id = var.compartment_ocid
}

resource "oci_core_drg_attachment" "DRGRegion1Attachment" {
  provider = oci.region1
  drg_id   = oci_core_drg.DRGRegion1.id
  vcn_id   = oci_core_virtual_network.VCNRegion1.id
}

resource "oci_core_drg" "DRGRegion2" {
  provider       = oci.region2
  display_name   = "DRGRegion2"
  compartment_id = var.compartment_ocid
}

resource "oci_core_drg_attachment" "DRGRegion2Attachment" {
  provider = oci.region2
  drg_id   = oci_core_drg.DRGRegion2.id
  vcn_id   = oci_core_virtual_network.VCNRegion2.id
}

resource "oci_core_drg" "DRGRegion3" {
  provider       = oci.region3
  display_name   = "DRGRegion3"
  compartment_id = var.compartment_ocid
}

resource "oci_core_drg_attachment" "DRGRegion3Attachment" {
  provider = oci.region3
  drg_id   = oci_core_drg.DRGRegion3.id
  vcn_id   = oci_core_virtual_network.VCNRegion3.id
}