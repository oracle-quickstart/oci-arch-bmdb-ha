## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

provider "oci" {
  version          = ">= 3.81.0"
  alias            = "region1"
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region1
}

provider "oci" {
  version          = ">= 3.65.0"
  alias            = "region2"
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region2
}

provider "oci" {
  version          = ">= 3.65.0"
  alias            = "region3"
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region3
}

provider "null" {
  version = "= 2.1.2"
}

provider "local" {
  version = "= 1.2.2"
}

provider "random" {
  version = "= 2.1.2"
}
