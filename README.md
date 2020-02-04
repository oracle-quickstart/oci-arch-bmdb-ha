# oci-arch-bmdb-ha

This set of scripts does the following tasks
1) Deploys two Bare Metal Database Systems running Oracle Database 12c Release 2 (12.2).
2) Configures one of these Database Systems to be the Primary and the other to be the Standby database in a Oracle Data Guard setup.
3) Deploys three compute instances, copies the Oracle Database 12c Release 2 (12.2) software to those three instances and configures them as FSFO observer nodes.


## Prerequisites

First off we'll need to do some pre deploy setup.  That's all detailed [here](https://github.com/oracle/oci-quickstart-prerequisites).

Download Oracle Database 12c Release 2 (12.2) software for Oracle Linux from [here](https://www.oracle.com/database/technologies/oracle12c-linux-12201-downloads.html).

These terraform scripts were written for Terraform version v0.11. You will need to update the code for higher versions.

## Deploying the architecture
1) Deploy a compute instance on OCI.
2) Copy the downloaded file linuxx64_12201_database.zip to that instance.
3) Download the files in the https://github.com/oracle-quickstart/oci-arch-bmdb-ha repository and copy them to the compute instance
4) Update the terraform.tfvars files in all the folders so that it is using variable values specific to your tenancy.
5) Edit main.sh and ensure that the pathname for the linuxx64_12201_database.zip reflects the path to the file on your compute instance.
6) Run terraform init on all the folders which have terraform scripts in them.
7) Execute main.sh

