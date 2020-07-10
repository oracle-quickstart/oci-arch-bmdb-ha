## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "null_resource" "Observer3_ConfigMgmt" {
  depends_on = [oci_core_instance.Observer3, oci_database_db_system.DBSystem, oci_database_data_guard_association.DBSystemStandby]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    inline = ["echo '== 1. Install oracle-rdbms-server-12cR1-preinstall'",
              "sudo -u root yum -y install oracle-rdbms-server-12cR1-preinstall",
              "sudo -u root yum -y install wget",

              "echo '== 2. Prepare directory structures for Oracle Client'",
              "sudo -u root rm -rf /u01/app/oraInventory",
              "sudo -u root mkdir -p /u01/app/oraInventory",
              "sudo -u root chown -R oracle:dba /u01/app/oraInventory", 
              "sudo -u root rm -rf /u01/app/oracle/*",
              "sudo -u root mkdir -p /u01/app/oracle",
              "sudo -u root chown -R oracle:oinstall /u01/app/oracle", 

              "echo '== 3. Download Oracle Client depot Bucket and install'",
              "sudo -u oracle wget -P /home/oracle ${var.oracle_client_bucket_PAR}",
              "sudo -u oracle rm -rf /home/oracle/${var.oracle_client_zip_file}*",
              "sudo -u oracle rm -rf /home/oracle/client",
              "sudo -u oracle unzip /home/oracle/${var.oracle_client_zip_file} -d /home/oracle/",
              "sudo -u oracle /home/oracle/client/runInstaller -silent UNIX_GROUP_NAME=dba INVENTORY_LOCATION=/u01/app/oraInventory ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1 ORACLE_BASE=/u01/app/oracle oracle.install.client.installType=Administrator -force",
              "sudo -u oracle sleep 3m",
              "sudo -u root /u01/app/oraInventory/orainstRoot.sh",
              "sudo /bin/su -c \"echo 'export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1' >> /home/oracle/.bash_profile\"",
              "sudo /bin/su -c \"echo 'export PATH=$PATH:/u01/app/oracle/product/12.2.0.1/dbhome_1/bin' >> /home/oracle/.bash_profile\"" 
             ]
    }
}


resource "null_resource" "Observer3_DGMGRL" {
  depends_on = [null_resource.Setup_DG_FSFO, null_resource.Observer3_ConfigMgmt, oci_core_instance.Observer3, oci_database_db_system.DBSystem, oci_database_data_guard_association.DBSystemStandby]

 provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }

    inline = ["sudo -u root rm -f /home/oracle/run_observer.sh",
              "sudo -u root rm -f /tmp/run_observer.sh"]
    }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }
    source      = "run_observer.sh"
    destination = "/tmp/run_observer.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
    }

    inline = ["echo '== 2. Start Observer with DGMGRL'",
              "sudo -u root cp /tmp/run_observer.sh /home/oracle/run_observer.sh",
              "sudo -u root chown oracle:oinstall /home/oracle/run_observer.sh",
              "sudo -u root chmod +x /home/oracle/run_observer.sh",
              "sudo -u root sed -i 's/DBAdminPassword/${var.DBAdminPassword}/g' /home/oracle/run_observer.sh",
              "sudo -u root sed -i 's/primarydb_db_unique_name/${data.oci_database_database.primarydb.db_unique_name}/g' /home/oracle/run_observer.sh",
              "sudo -u oracle /home/oracle/run_observer.sh",

              "echo '== 3. Show observer log'",
              "sudo -u oracle sleep 1m",
              "sudo -u oracle cat /home/oracle/observer.log"
             ]
    }
}

resource "null_resource" "Observer2_ConfigMgmt" {
  depends_on = [oci_core_instance.Observer2, oci_database_db_system.DBSystem, oci_database_data_guard_association.DBSystemStandby]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer2_VNIC1.private_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
      bastion_host = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      bastion_port = "22"
      bastion_user = "opc"
      bastion_private_key = file(var.ssh_private_key)
    }
    inline = ["echo '== 1. Install oracle-rdbms-server-12cR1-preinstall'",
              "sudo -u root yum -y install oracle-rdbms-server-12cR1-preinstall",
              "sudo -u root yum -y install wget",

              "echo '== 2. Prepare directory structures for Oracle Client'",
              "sudo -u root rm -rf /u01/app/oraInventory",
              "sudo -u root mkdir -p /u01/app/oraInventory",
              "sudo -u root chown -R oracle:dba /u01/app/oraInventory", 
              "sudo -u root rm -rf /u01/app/oracle/*",
              "sudo -u root mkdir -p /u01/app/oracle",
              "sudo -u root chown -R oracle:oinstall /u01/app/oracle", 

              "echo '== 3. Download Oracle Client depot Bucket and install'",
              "sudo -u oracle wget -P /home/oracle ${var.oracle_client_bucket_PAR}",
              "sudo -u oracle rm -rf /home/oracle/${var.oracle_client_zip_file}*",
              "sudo -u oracle rm -rf /home/oracle/client",
              "sudo -u oracle unzip /home/oracle/${var.oracle_client_zip_file} -d /home/oracle/",
              "sudo -u oracle /home/oracle/client/runInstaller -silent UNIX_GROUP_NAME=dba INVENTORY_LOCATION=/u01/app/oraInventory ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1 ORACLE_BASE=/u01/app/oracle oracle.install.client.installType=Administrator -force",
              "sudo -u oracle sleep 3m",
              "sudo -u root /u01/app/oraInventory/orainstRoot.sh",
              "sudo /bin/su -c \"echo 'export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1' >> /home/oracle/.bash_profile\"",
              "sudo /bin/su -c \"echo 'export PATH=$PATH:/u01/app/oracle/product/12.2.0.1/dbhome_1/bin' >> /home/oracle/.bash_profile\"" 
             ]
    }
}

resource "null_resource" "Observer2_DGMGRL" {
  depends_on = [null_resource.Setup_DG_FSFO, null_resource.Observer2_ConfigMgmt, oci_core_instance.Observer2, oci_database_db_system.DBSystem, oci_database_data_guard_association.DBSystemStandby]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer2_VNIC1.private_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
      bastion_host = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      bastion_port = "22"
      bastion_user = "opc"
      bastion_private_key = file(var.ssh_private_key)
    }

    inline = ["sudo -u root rm -f /home/oracle/run_observer.sh",
              "sudo -u root rm -f /tmp/run_observer.sh"]
    }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer2_VNIC1.private_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
      bastion_host = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      bastion_port = "22"
      bastion_user = "opc"
      bastion_private_key = file(var.ssh_private_key)
    }
    source      = "run_observer.sh"
    destination = "/tmp/run_observer.sh"
  }


  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer2_VNIC1.private_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
      bastion_host = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      bastion_port = "22"
      bastion_user = "opc"
      bastion_private_key = file(var.ssh_private_key)
    }

    inline = ["echo '== 1. Configure TNSNAMES.ORA'",
              "sudo /bin/su -c \"echo '${data.oci_database_database.primarydb.db_unique_name} = ${data.oci_database_database.primarydb.connection_strings[0].cdb_ip_default}' >> /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora\"",
              "sudo /bin/su -c \"echo '${data.oci_database_database.standbydb.db_unique_name} = ${data.oci_database_database.standbydb.connection_strings[0].cdb_ip_default}' >> /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora\"", 
              "sudo su - oracle cat /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora",

              "echo '== 2. Start Observer with DGMGRL'",
              "sudo -u root cp /tmp/run_observer.sh /home/oracle/run_observer.sh",
              "sudo -u root chown oracle:oinstall /home/oracle/run_observer.sh",
              "sudo -u root chmod +x /home/oracle/run_observer.sh",
              "sudo -u root sed -i 's/DBAdminPassword/${var.DBAdminPassword}/g' /home/oracle/run_observer.sh",
              "sudo -u root sed -i 's/primarydb_db_unique_name/${data.oci_database_database.primarydb.db_unique_name}/g' /home/oracle/run_observer.sh",
              "sudo -u oracle /home/oracle/run_observer.sh",

              "echo '== 3. Show observer log'",
              "sudo -u oracle sleep 1m",
              "sudo -u oracle cat /home/oracle/observer.log"
              ]
    }
}

resource "null_resource" "Observer1_ConfigMgmt" {
  depends_on = [oci_core_instance.Observer1, oci_database_db_system.DBSystem, oci_database_data_guard_association.DBSystemStandby]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer1_VNIC1.private_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
      bastion_host = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      bastion_port = "22"
      bastion_user = "opc"
      bastion_private_key = file(var.ssh_private_key)
    }
    inline = ["echo '== 1. Install oracle-rdbms-server-12cR1-preinstall'",
              "sudo -u root yum -y install oracle-rdbms-server-12cR1-preinstall",
              "sudo -u root yum -y install wget",

              "echo '== 2. Prepare directory structures for Oracle Client'",
              "sudo -u root rm -rf /u01/app/oraInventory",
              "sudo -u root mkdir -p /u01/app/oraInventory",
              "sudo -u root chown -R oracle:dba /u01/app/oraInventory", 
              "sudo -u root rm -rf /u01/app/oracle/*",
              "sudo -u root mkdir -p /u01/app/oracle",
              "sudo -u root chown -R oracle:oinstall /u01/app/oracle", 

              "echo '== 3. Download Oracle Client depot Bucket and install'",
              "sudo -u oracle wget -P /home/oracle ${var.oracle_client_bucket_PAR}",
              "sudo -u oracle rm -rf /home/oracle/${var.oracle_client_zip_file}*",
              "sudo -u oracle rm -rf /home/oracle/client",
              "sudo -u oracle unzip /home/oracle/${var.oracle_client_zip_file} -d /home/oracle/",
              "sudo -u oracle /home/oracle/client/runInstaller -silent UNIX_GROUP_NAME=dba INVENTORY_LOCATION=/u01/app/oraInventory ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1 ORACLE_BASE=/u01/app/oracle oracle.install.client.installType=Administrator -force",
              "sudo -u oracle sleep 3m",
              "sudo -u root /u01/app/oraInventory/orainstRoot.sh",
              "sudo /bin/su -c \"echo 'export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1' >> /home/oracle/.bash_profile\"",
              "sudo /bin/su -c \"echo 'export PATH=$PATH:/u01/app/oracle/product/12.2.0.1/dbhome_1/bin' >> /home/oracle/.bash_profile\"" 
             ]
    }
}

resource "null_resource" "Observer1_DGMGRL" {
  depends_on = [null_resource.Setup_DG_FSFO, null_resource.Observer1_ConfigMgmt, oci_core_instance.Observer1, oci_database_db_system.DBSystem, oci_database_data_guard_association.DBSystemStandby]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer1_VNIC1.private_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
      bastion_host = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      bastion_port = "22"
      bastion_user = "opc"
      bastion_private_key = file(var.ssh_private_key)
    }

    inline = ["sudo -u root rm -f /home/oracle/run_observer.sh",
              "sudo -u root rm -f /tmp/run_observer.sh"]
    }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer1_VNIC1.private_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
      bastion_host = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      bastion_port = "22"
      bastion_user = "opc"
      bastion_private_key = file(var.ssh_private_key)
    }
    source      = "run_observer.sh"
    destination = "/tmp/run_observer.sh"
  }


  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = data.oci_core_vnic.Observer1_VNIC1.private_ip_address
      private_key = file(var.ssh_private_key)
      script_path = "/home/opc/myssh.sh"
      agent       = false
      timeout     = "10m"
      bastion_host = data.oci_core_vnic.Observer3_VNIC1.public_ip_address
      bastion_port = "22"
      bastion_user = "opc"
      bastion_private_key = file(var.ssh_private_key)
    }

    inline = ["echo '== 1. Configure TNSNAMES.ORA'",
              "sudo /bin/su -c \"echo '${data.oci_database_database.primarydb.db_unique_name} = ${data.oci_database_database.primarydb.connection_strings[0].cdb_ip_default}' >> /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora\"",
              "sudo /bin/su -c \"echo '${data.oci_database_database.standbydb.db_unique_name} = ${data.oci_database_database.standbydb.connection_strings[0].cdb_ip_default}' >> /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora\"", 
              "sudo su - oracle cat /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora",

              "echo '== 2. Start Observer with DGMGRL'",
              "sudo -u root cp /tmp/run_observer.sh /home/oracle/run_observer.sh",
              "sudo -u root chown oracle:oinstall /home/oracle/run_observer.sh",
              "sudo -u root chmod +x /home/oracle/run_observer.sh",
              "sudo -u root sed -i 's/DBAdminPassword/${var.DBAdminPassword}/g' /home/oracle/run_observer.sh",
              "sudo -u root sed -i 's/primarydb_db_unique_name/${data.oci_database_database.primarydb.db_unique_name}/g' /home/oracle/run_observer.sh",
              "sudo -u oracle /home/oracle/run_observer.sh",

              "echo '== 3. Show observer log'",
              "sudo -u oracle sleep 1m",
              "sudo -u oracle cat /home/oracle/observer.log"
              ]
    }
}
