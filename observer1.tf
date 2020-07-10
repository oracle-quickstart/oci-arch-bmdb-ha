## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Gets a list of Availability Domains
data "oci_identity_availability_domains" "R1-ADs" {
  provider       = oci.region1
  compartment_id = var.tenancy_ocid
}

# Gets the Id of a specific OS Images
data "oci_core_images" "R1-OSImageLocal" {
  provider       = oci.region1
  compartment_id = var.compartment_ocid
  display_name   = var.OsImage
}

resource "oci_core_instance" "Observer1" {
  provider            = oci.region1
  availability_domain = lookup(data.oci_identity_availability_domains.R1-ADs.availability_domains[0], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "Observer1"
  shape               = var.Shape
  subnet_id           = oci_core_subnet.SubnetRegion1.id
  source_details {
    source_type = "image"
    source_id   = lookup(data.oci_core_images.R1-OSImageLocal.images[0], "id")
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
  }
  create_vnic_details {
    subnet_id = oci_core_subnet.SubnetRegion1.id
    assign_public_ip = false
  }
}

data "oci_core_vnic_attachments" "Observer1_VNIC1_attach" {
  provider       = oci.region1
  availability_domain = lookup(data.oci_identity_availability_domains.R1-ADs.availability_domains[0], "name")
  compartment_id      = var.compartment_ocid
  instance_id         = oci_core_instance.Observer1.id
}

data "oci_core_vnic" "Observer1_VNIC1" {
  provider       = oci.region1
  vnic_id = data.oci_core_vnic_attachments.Observer1_VNIC1_attach.vnic_attachments.0.vnic_id
}

output "Observer1_PrivateIP" {
  value = [data.oci_core_vnic.Observer1_VNIC1.private_ip_address]
}
