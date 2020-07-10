## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_dhcp_options" "DhcpOptionsRegion1" {
  provider       = oci.region1
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.VCNRegion1.id
  display_name   = "DHCPOptionsRegion1"

  // required
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  // optional
  options {
    type                = "SearchDomain"
    search_domain_names = ["example.com"]
  }
}

resource "oci_core_dhcp_options" "DhcpOptionsRegion2" {
  provider       = oci.region2
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.VCNRegion2.id
  display_name   = "DHCPOptionsRegion2"

  // required
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  // optional
  options {
    type                = "SearchDomain"
    search_domain_names = ["example.com"]
  }
}

resource "oci_core_dhcp_options" "DhcpOptionsRegion3" {
  provider       = oci.region3
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.VCNRegion3.id
  display_name   = "DHCPOptionsRegion3"

  // required
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  // optional
  options {
    type                = "SearchDomain"
    search_domain_names = ["example.com"]
  }
}
