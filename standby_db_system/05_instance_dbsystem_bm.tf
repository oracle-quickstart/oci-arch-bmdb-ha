# -- db system specific vars (fill the terraform.tfvars file)
variable "BM-DBNodeShape" 		{}
variable "BM-CPUCoreCount" 		{}
variable "BM-DBEdition" 		{}
variable "BM-DBAdminPassword"	 	{}
variable "BM-DBName" 			{}
variable "BM-DBVersion" 		{}
variable "BM-DBDisplayName" 		{}
variable "BM-DBDiskRedundancy" 		{}
variable "BM-DBNodeDisplayName" 	{}
variable "BM-DBNodeDomainName" 		{}
variable "BM-DBNodeHostName" 		{}
variable "BM-NCharacterSet" 		{}
variable "BM-CharacterSet" 		{}
variable "BM-DBWorkload" 		{}
variable "BM-PDBName" 			{}
variable "BM-DataStorageSizeInGB" 	{}
variable "BM-LicenseModel" 		{}
variable "BM-NodeCount" 		{}

# ------ Create a DB Systems on Bare Metal shape BM.DenseIO1.36
resource "oci_database_db_system" "standby-db-bm" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id = "${var.compartment_ocid}"
  cpu_core_count = "${var.BM-CPUCoreCount}"
  database_edition = "${var.BM-DBEdition}"
  db_home {
    database {
      "admin_password" = "${var.BM-DBAdminPassword}"
      "db_name" = "${var.BM-DBName}"
      "character_set" = "${var.BM-CharacterSet}"
      "ncharacter_set" = "${var.BM-NCharacterSet}"
      "db_workload" = "${var.BM-DBWorkload}"
      "pdb_name" = "${var.BM-PDBName}"
    }
    db_version = "${var.BM-DBVersion}"
    display_name = "${var.BM-DBDisplayName}"
  }
  disk_redundancy = "${var.BM-DBDiskRedundancy}"
  shape = "${var.BM-DBNodeShape}"
  subnet_id = "${oci_core_subnet.standby-public-subnet1.id}"
  # trimspace needed as a workaround to issue https://github.com/hashicorp/terraform/issues/7889
  ssh_public_keys = ["${trimspace(file(var.ssh_public_key_file))}"]
  display_name = "${var.BM-DBNodeDisplayName}"
  domain = "${var.BM-DBNodeDomainName}"
  hostname = "${var.BM-DBNodeHostName}"
  data_storage_percentage = "40"
  license_model = "${var.BM-LicenseModel}"
}

# ------ Configure the NFS client and mount point on the DB server

# Get DB node list
data "oci_database_db_nodes" "standby-bm" {
  compartment_id = "${var.compartment_ocid}"
  db_system_id = "${oci_database_db_system.standby-db-bm.id}"
}

# Get DB node details
data "oci_database_db_node" "standby-bm" {
  db_node_id = "${lookup(data.oci_database_db_nodes.standby-bm.db_nodes[0], "id")}"
}

# Gets the OCID of the first (default) vNIC
data "oci_core_vnic" "standby-bm" {
  vnic_id = "${data.oci_database_db_node.standby-bm.vnic_id}"
}

resource "null_resource" "standby-bm" {
  provisioner "file" {
    connection {
	agent = false
	timeout = "10m"
	host = "${data.oci_core_vnic.standby-bm.public_ip_address}"
	user = "opc"
	private_key = "${file(var.ssh_private_key_file)}"
    }
    source = "${var.ScriptFile_db}"
    destination = "~/script_db.sh"
  }    
    
  provisioner "remote-exec" {
    connection {
	agent = false
	timeout = "10m"
	host = "${data.oci_core_vnic.standby-bm.public_ip_address}"
	user = "opc"
	private_key = "${file(var.ssh_private_key_file)}"
    }
    inline = [
	"chmod +x ~/script_db.sh",
	"sudo ~/script_db.sh",
    ]
  }
}

# ------ Get the public IP of the DBsystem and display it on screen
output "Public IP of the DB system-BM" {
  value = ["${data.oci_core_vnic.standby-bm.public_ip_address}"]
}




