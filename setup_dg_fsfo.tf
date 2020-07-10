## Copyright (c) 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "null_resource" "Setup_DG_FSFO" {
  depends_on = [null_resource.Observer3_ConfigMgmt, oci_database_db_system.DBSystem, oci_database_data_guard_association.DBSystemStandby]

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

    inline = ["sudo -u root rm -f /home/oracle/setup_dg_fsfo.sh",
              "sudo -u root rm -f /tmp/setup_dg_fsfo.sh"]
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
    source      = "setup_dg_fsfo.sh"
    destination = "/tmp/setup_dg_fsfo.sh"
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

    inline = ["echo '== 1. Configure TNSNAMES.ORA'",
              "sudo /bin/su -c \"echo '${data.oci_database_database.primarydb.db_unique_name} = ${data.oci_database_database.primarydb.connection_strings[0].cdb_ip_default}' >> /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora\"",
              "sudo /bin/su -c \"echo '${data.oci_database_database.standbydb.db_unique_name} = ${data.oci_database_database.standbydb.connection_strings[0].cdb_ip_default}' >> /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora\"", 
              "sudo -u oracle cat /u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora",

              "echo '== 2. Setup DataGuard Fast Start FailOver (FSFO) with DGMGRL'",
              "sudo -u root cp /tmp/setup_dg_fsfo.sh /home/oracle/setup_dg_fsfo.sh",
              "sudo -u root chown oracle:oinstall /home/oracle/setup_dg_fsfo.sh",
              "sudo -u root chmod +x /home/oracle/setup_dg_fsfo.sh",
              "sudo -u root rm -rf /home/oracle/dg_fsfo*.log",
              "sudo -u root sed -i 's/DBAdminPassword/${var.DBAdminPassword}/g' /home/oracle/setup_dg_fsfo.sh",
              "sudo -u root sed -i 's/primarydb_db_unique_name/${data.oci_database_database.primarydb.db_unique_name}/g' /home/oracle/setup_dg_fsfo.sh",
              "sudo -u root sed -i 's/standbydb_db_unique_name/${data.oci_database_database.standbydb.db_unique_name}/g' /home/oracle/setup_dg_fsfo.sh",
              "sudo -u oracle /home/oracle/setup_dg_fsfo.sh",

              "echo '== 3. Show FSFO logs'",
              "sudo -u oracle cat /home/oracle/dg_fsfo1.log",
              "sudo -u oracle cat /home/oracle/dg_fsfo2.log",
              "sudo -u oracle cat /home/oracle/dg_fsfo3.log",
              "sudo -u oracle cat /home/oracle/dg_fsfo4.log",
              "sudo -u oracle cat /home/oracle/dg_fsfo5.log",

              "echo '   '",
              "echo '== END of FSFO setup'"
             ]
    }
}

