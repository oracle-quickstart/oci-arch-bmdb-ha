## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_database_db_system" "DBSystem" {
  provider = oci.region1
  availability_domain = lookup(data.oci_identity_availability_domains.R1-ADs.availability_domains[0], "name")
  compartment_id = var.compartment_ocid
  cpu_core_count = var.CPUCoreCount
  database_edition = var.DBEdition
  db_home {
    database {
      admin_password = var.DBAdminPassword
      db_name = var.DBName
      character_set = var.CharacterSet
      ncharacter_set = var.NCharacterSet
      db_workload = var.DBWorkload
      pdb_name = var.PDBName
    }
    db_version = var.DBVersion
    display_name = var.DBDisplayName
  }
  disk_redundancy = var.DBDiskRedundancy
  shape = var.DBNodeShape
  subnet_id = oci_core_subnet.SubnetRegion1.id
  ssh_public_keys = [file(var.ssh_public_key)]
  display_name = var.DBSystemDisplayName
  domain = var.DBNodeDomainName
  hostname = var.DBNodeHostName
  data_storage_percentage = "40"
  data_storage_size_in_gb = var.DataStorageSizeInGB
  license_model = var.LicenseModel
  node_count = var.NodeCount
}

resource "oci_database_data_guard_association" "DBSystemStandby" {
    provider = oci.region1
    creation_type = "NewDbSystem"
    database_admin_password = var.DBAdminPassword
    database_id = oci_database_db_system.DBSystem.db_home[0].database[0].id
    protection_mode = "MAXIMUM_PERFORMANCE"
    transport_type = "ASYNC"
    delete_standby_db_home_on_delete = "true"

    availability_domain = lookup(data.oci_identity_availability_domains.R2-ADs.availability_domains[1], "name")
    display_name = var.DBStandbySystemDisplayName
    hostname = var.DBStandbyNodeHostName
    shape = var.DBStandbyNodeShape
    subnet_id = oci_core_subnet.SubnetRegion2.id
}

data "oci_database_db_nodes" "DBNodeList" {
  provider = oci.region1
  compartment_id = var.compartment_ocid
  db_system_id = oci_database_db_system.DBSystem.id
}

data "oci_database_db_node" "DBNodeDetails" {
  provider = oci.region1
  db_node_id = lookup(data.oci_database_db_nodes.DBNodeList.db_nodes[0], "id")
}

data "oci_core_vnic" "DBSystem_VNIC1" {
  provider = oci.region1
  vnic_id = data.oci_database_db_node.DBNodeDetails.vnic_id
}

output "DBServer_PrivateIP" {
   value = [data.oci_core_vnic.DBSystem_VNIC1.private_ip_address]
}

data "oci_database_database" "primarydb" {
  provider       = oci.region1
  database_id    = oci_database_db_system.DBSystem.db_home[0].database[0].id
}

data "oci_database_data_guard_association" "dgassociation" {
  provider                  = oci.region1
  data_guard_association_id = oci_database_data_guard_association.DBSystemStandby.id
  database_id               = oci_database_db_system.DBSystem.db_home[0].database[0].id
}

data "oci_database_database" "standbydb" {
  provider       = oci.region2
  database_id    = data.oci_database_data_guard_association.dgassociation.peer_database_id
}

#output "DBServer_ConnectString" {
#   value = [data.oci_database_database.primarydb.connection_strings[0].cdb_ip_default]
#}

#output "DBStandbyServer_ConnectString" {
#   value = [data.oci_database_database.standbydb.connection_strings[0].cdb_ip_default]
#}
