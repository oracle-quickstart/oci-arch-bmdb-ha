## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_route_table" "RouteTableRegion3" {
  provider       = oci.region3
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.VCNRegion3.id
  display_name   = "RouteTableRegion3"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.InternetGatewayRegion3.id
  }

  route_rules {
    destination       = var.VCNRegion1-CIDR
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.DRGRegion3.id
  }

  route_rules {
    destination       = var.VCNRegion2-CIDR
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.DRGRegion3.id
  }
}
