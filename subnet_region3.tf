## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_subnet" "SubnetRegion3" {
  provider          = oci.region3
  cidr_block        = var.SubnetRegion3-CIDR
  display_name      = "SubnetRegion3"
  dns_label         = "subnet3"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.VCNRegion3.id
  route_table_id    = oci_core_route_table.RouteTableRegion3.id
  dhcp_options_id   = oci_core_dhcp_options.DhcpOptionsRegion3.id
  security_list_ids = [oci_core_security_list.SecurityListSSHRegion3.id]
}


