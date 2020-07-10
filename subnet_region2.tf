## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_subnet" "SubnetRegion2" {
  provider                   = oci.region2
  cidr_block                 = var.SubnetRegion2-CIDR
  display_name               = "SubnetRegion2"
  dns_label                  = "subnet2"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.VCNRegion2.id
  route_table_id             = oci_core_route_table.RouteTableRegion2.id
  dhcp_options_id            = oci_core_dhcp_options.DhcpOptionsRegion2.id
  security_list_ids          = [oci_core_security_list.SecurityListSQLNetRegion2.id, oci_core_security_list.SecurityListSSHRegion2.id]
  prohibit_public_ip_on_vnic = true
}


