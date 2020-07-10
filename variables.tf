## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "fingerprint" {}
variable "user_ocid" {}
variable "private_key_path" {}
variable "ssh_private_key" {}
variable "ssh_public_key" {}
variable "region1" {}
variable "region2" {}
variable "region3" {}
variable "DBAdminPassword" {}
variable "oracle_client_bucket_PAR" {}
variable "oracle_client_zip_file" {}


variable "VCNRegion1-CIDR" {
  default = "10.0.0.0/16"
}

variable "VCNRegion2-CIDR" {
  default = "192.168.0.0/16"
}

variable "VCNRegion3-CIDR" {
  default = "172.16.0.0/16"
}

variable "SubnetRegion1-CIDR" {
  default = "10.0.1.0/24"
}

variable "SubnetRegion2-CIDR" {
  default = "192.168.1.0/24"
}

variable "SubnetRegion3-CIDR" {
  default = "172.16.1.0/24"
}

variable "Shape" {
  default = "VM.Standard2.1"
}

variable "OsImage" {
  default = "Oracle-Linux-7.8-2020.05.26-0"
}

# DBSystem specific 
variable "DBNodeShape" {
    default = "BM.DenseIO2.52"
}

# DBStandbySystem specific 
variable "DBStandbyNodeShape" {
    default = "BM.DenseIO2.52"
}

variable "CPUCoreCount" {
    default = "2"
}

variable "DBEdition" {
    default = "ENTERPRISE_EDITION"
}

variable "DBName" {
    default = "ORCL"
}

variable "DBVersion" {
    default = "12.2.0.1"
}

variable "DBDisplayName" {
    default = "ORCL"
}

variable "DBHomeDisplayName" {
    default = "DBHome"
}

variable "DBDiskRedundancy" {
    default = "HIGH"
}

variable "DBSystemDisplayName" {
    default = "DBSystem"
}

variable "DBStandbySystemDisplayName" {
    default = "DBStandbySystem"
}

variable "DBNodeDomainName" {
    default = "subnet1.vcn1.oraclevcn.com"
}

variable "DBNodeHostName" {
    default = "dbpri"
}

variable "DBStandbyNodeHostName" {
    default = "dbstb"
}

variable "HostUserName" {
    default = "opc"
}

variable "NCharacterSet" {
  default = "AL16UTF16"
}

variable "CharacterSet" {
  default = "AL32UTF8"
}

variable "DBWorkload" {
  default = "OLTP"
}

variable "PDBName" {
  default = "pdb1"
}

variable "DataStorageSizeInGB" {
  default = "256"
}

variable "LicenseModel" {
  default = "LICENSE_INCLUDED"
}

variable "NodeCount" {
  default = "1"
}
