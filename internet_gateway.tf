## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_internet_gateway" "InternetGatewayRegion3" {
  provider       = oci.region3
  compartment_id = var.compartment_ocid
  display_name   = "InternetGatewayRegion3"
  vcn_id         = oci_core_virtual_network.VCNRegion3.id
}
