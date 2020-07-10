## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_subnet" "SubnetRegion1" {
  provider                   = oci.region1
  cidr_block                 = var.SubnetRegion1-CIDR
  display_name               = "SubnetRegion1"
  dns_label                  = "subnet1"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.VCNRegion1.id
  route_table_id             = oci_core_route_table.RouteTableRegion1.id
  dhcp_options_id            = oci_core_dhcp_options.DhcpOptionsRegion1.id
  security_list_ids          = [oci_core_security_list.SecurityListSQLNetRegion1.id, oci_core_security_list.SecurityListSSHRegion1.id]
  prohibit_public_ip_on_vnic = true
}


