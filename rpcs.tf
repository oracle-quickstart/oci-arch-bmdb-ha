## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_remote_peering_connection" "RPCRegion1_to_Region2" {
  provider         = oci.region1
  compartment_id   = var.compartment_ocid
  drg_id           = oci_core_drg.DRGRegion1.id
  display_name     = "RPCRegion1_to_Region2"
  peer_id          = oci_core_remote_peering_connection.RPCRegion2_to_Region1.id
  peer_region_name = var.region2
}

resource "oci_core_remote_peering_connection" "RPCRegion1_to_Region3" {
  provider         = oci.region1
  compartment_id   = var.compartment_ocid
  drg_id           = oci_core_drg.DRGRegion1.id
  display_name     = "RPCRegion1_to_Region3"
  peer_id          = oci_core_remote_peering_connection.RPCRegion3_to_Region1.id
  peer_region_name = var.region3
}

resource "oci_core_remote_peering_connection" "RPCRegion2_to_Region1" {
  provider       = oci.region2
  compartment_id = var.compartment_ocid
  drg_id         = oci_core_drg.DRGRegion2.id
  display_name   = "RPCRegion2_to_Region1"
}

resource "oci_core_remote_peering_connection" "RPCRegion2_to_Region3" {
  provider         = oci.region2
  compartment_id   = var.compartment_ocid
  drg_id           = oci_core_drg.DRGRegion2.id
  display_name     = "RPCRegion2_to_Region3"
  peer_id          = oci_core_remote_peering_connection.RPCRegion3_to_Region2.id
  peer_region_name = var.region3
}

resource "oci_core_remote_peering_connection" "RPCRegion3_to_Region1" {
  provider         = oci.region3
  compartment_id   = var.compartment_ocid
  drg_id           = oci_core_drg.DRGRegion3.id
  display_name     = "RPCRegion3_to_Region1"
}

resource "oci_core_remote_peering_connection" "RPCRegion3_to_Region2" {
  provider       = oci.region3
  compartment_id = var.compartment_ocid
  drg_id         = oci_core_drg.DRGRegion3.id
  display_name   = "RPCRegion3_to_Region2"
}