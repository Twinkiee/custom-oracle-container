#!/bin/sh
#
# $Header: dbaas/docker/build/dbsetup/setup/configDBora.sh rduraisa_docker_122_image/6 2017/04/02 06:29:55 rduraisa Exp $
#
# configDBora.sh
#
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      configDBora.sh - configure database as oracle user
#
#    DESCRIPTION
#      rename the DB to customized name
#
#    NOTES
#      run as oracle
#
#    MODIFIED   (MM/DD/YY)
#    rduraisa    03/02/17 - Modify scripts to build for 12102 and 12201
#    xihzhang    10/25/16 - Remove EE bundles
#    xihzhang    08/08/16 - Remove privilege mode
#    xihzhang    05/23/16 - Creation
#

echo `date`
echo "Configure DB as oracle user"

# basic parameters
SETUP_DIR=/home/oracle/setup

IFS='.' read -r -a dbrelarr <<< 12.2.0

if [[ ${dbrelarr[0]} == 12 && ${dbrelarr[1]} == 1 ]];
then
    PATCH_LOG=${SETUP_DIR}/log/patchDB.log
    # unpatch opc features
    echo "Patching Database ...."
    /bin/bash ${SETUP_DIR}/patchDB.sh 2>&1 >> ${PATCH_LOG}

    $ORACLE_HOME/bin/relink as_installed
fi

#setup directories and soft links
echo "Setup Database directories ..."
mkdir -p /ORCL/u01/app/oracle/diag /u01/app/oracle /u02/app/oracle /u03/app/oracle /u04/app/oracle
mkdir -p $TNS_ADMIN
ln -s /ORCL/$ORACLE_HOME/dbs $ORACLE_HOME/dbs
ln -s /ORCL/u01/app/oracle/diag /u01/app/oracle/diag
ln -s /ORCL/u02/app/oracle/audit /u02/app/oracle/audit
ln -s /ORCL/u02/app/oracle/oradata /u02/app/oracle/oradata
ln -s /ORCL/u03/app/oracle/fast_recovery_area /u03/app/oracle/fast_recovery_area
ln -s /ORCL/u04/app/oracle/redo /u04/app/oracle/redo

if [[ $EXISTING_DB = false ]];
then
  cd /u01/app/oracle/product/12.2.0/dbhome_1/dbs/
  # set domain
  echo "*.db_domain='$DB_DOMAIN'" >> initORCLCDB.ora
  # set sga & pga
  MEMORY=${DB_MEMORY//[!0-9]/}
  SGA_MEM=$(($MEMORY * 640))M
  PGA_MEM=$(($MEMORY * 384))M
  echo "*.sga_target=$SGA_MEM" >> initORCLCDB.ora
  echo "*.pga_aggregate_target=$PGA_MEM" >> initORCLCDB.ora

  # create the diag directory to avoid errors with the below mv command
  mkdir -p /u01/app/oracle/diag/rdbms/orclcdb/ORCLCDB

  if [ "$DB_SID" != "ORCLCDB" ]
  then
  # mount db
      sqlplus / as sysdba 2>&1 <<EOF
      startup mount pfile=/u01/app/oracle/product/12.2.0/dbhome_1/dbs/initORCLCDB.ora;
      exit;
EOF

  # nid change name
      echo "NID change db name"
      echo "Y" | nid target=/ dbname=$DB_SID

  # update init.ora
      rm -f init$DB_SID.ora
      cp initORCLCDB.ora init$DB_SID.ora

  # change sid
      sed -i -- "s#ORCLCDB#$DB_SID#g" init$DB_SID.ora

  # rename all the dirs/files
      mv /u01/app/oracle/diag/rdbms/orclcdb/ORCLCDB /u01/app/oracle/diag/rdbms/orclcdb/$DB_SID
      mv /u01/app/oracle/diag/rdbms/orclcdb /u01/app/oracle/diag/rdbms/${DB_SID,,}
      mv /u02/app/oracle/audit/ORCLCDB /u02/app/oracle/audit/$DB_SID
      mv /u02/app/oracle/oradata/ORCLCDB /u02/app/oracle/oradata/$DB_SID   # cp -R
      mv /u03/app/oracle/fast_recovery_area/ORCLCDB /u03/app/oracle/fast_recovery_area/$DB_SID
      mv /u02/app/oracle/oradata/$DB_SID/cntrlORCLCDB.dbf /u02/app/oracle/oradata/$DB_SID/cntrl${DB_SID}.dbf
      mv /u03/app/oracle/fast_recovery_area/$DB_SID/cntrlORCLCDB2.dbf /u03/app/oracle/fast_recovery_area/$DB_SID/cntrl${DB_SID}2.dbf

  # make links
      cd /u02/app/oracle/oradata/
      ln -s $DB_SID ORCLCDB

  # change SID
      export ORACLE_SID=$DB_SID

  # db setup
  # enable archivelog + change global name + create spfile
      NEW_ORA=/u01/app/oracle/product/12.2.0/dbhome_1/dbs/init$DB_SID.ora
      sqlplus / as sysdba 2>&1 <<EOF
      create spfile from pfile='$NEW_ORA';
      startup mount;
      alter database open resetlogs;
      alter database rename global_name to $DB_SID.$DB_DOMAIN;
      show parameter spfile;
      show parameter encrypt_new_tablespaces;
      alter user sys identified by "$DB_PASSWD";
      alter user system identified by "$DB_PASSWD";
      exit;
EOF

  else
  # db setup
  # enable archivelog + change global name + create spfile
      NEW_ORA=/u01/app/oracle/product/12.2.0/dbhome_1/dbs/init$DB_SID.ora
      sqlplus / as sysdba 2>&1 <<EOF
      create spfile from pfile='$NEW_ORA';
      startup;
      alter database rename global_name to $DB_SID.$DB_DOMAIN;
      show parameter spfile;
      show parameter encrypt_new_tablespaces;
      alter user sys identified by "$DB_PASSWD";
      alter user system identified by "$DB_PASSWD";
      exit;
EOF
  fi

  # create orapw
  echo "update password"
  echo "$DB_PASSWD" | orapwd file=/u01/app/oracle/product/12.2.0/dbhome_1/dbs/orapw$DB_SID

  # create pdb
  echo "create pdb : $DB_PDB"
  sqlplus / as sysdba 2>&1 <<EOF
  
    create pluggable database $DB_PDB ADMIN USER sys1 identified by "$DB_PASSWD"
    default tablespace users
      datafile '/u02/app/oracle/oradata/ORCLCDB/orclpdb1/users01.dbf'
      size 10M reuse autoextend on maxsize unlimited
      file_name_convert=('/u02/app/oracle/oradata/ORCL/pdbseed','/u02/app/oracle/oradata/ORCLCDB/orclpdb1');
    alter pluggable database $DB_PDB open;
    alter pluggable database all save state;
	
	
	
	CREATE USER c##HOadmin IDENTIFIED BY oracle;
GRANT create session, connect, dba TO c##HOadmin CONTAINER=ALL;

ho mkdir -p /u02/app/oracle/oradata/ORCLCDB/HO_PDB

REM CREATE PLUGGABLE DATABASE HO_PDB ADMIN USER HOadmin IDENTIFIED BY oracle FILE_NAME_CONVERT = ('/u02/app/oracle/oradata/ORCLCDB/pdbseed', '/ORCL/u02/app/oracle/oradata/ORCLCDB/HO_PDB');
CREATE PLUGGABLE DATABASE HO_PDB ADMIN USER HOadmin IDENTIFIED BY Kraken96 CREATE_FILE_DEST='/u02/app/oracle/oradata/ORCLCDB/HO_PDB';
ALTER SESSION SET CONTAINER=HO_PDB;
alter pluggable database HO_PDB open services=all;
GRANT connect, resource, pdb_dba, alter database TO HOadmin; 
alter system set NLS_LANGUAGE = 'ENGLISH' scope = SPFILE;
alter system set NLS_COMP = 'LINGUISTIC' scope = SPFILE;
alter system set NLS_SORT = 'EBCDIC' scope = SPFILE;
REM Specify Character not byte length for CHAR and VARCHAR data types since we are using a multi byte code page and not a single byte code page like the original EBCDIC
alter system set NLS_LENGTH_SEMANTICS  = 'CHAR'  scope = SPFILE;
REM NLS_SESSION_PARAMETERS shows the NLS parameters and their values for the session that is querying the view. It does not show information about the character set.
REM NLS_INSTANCE_PARAMETERS shows the current NLS instance parameters that have been explicitly set and the values of the NLS instance parameters.
REM NLS_DATABASE_PARAMETERS shows the values of the NLS parameters for the database. The values are stored in the database.
set linesize 100
COLUMN parameter FORMAT A40
COLUMN value FORMAT A40
select parameter, value from NLS_DATABASE_PARAMETERS order by parameter ASC;
select parameter, value from NLS_INSTANCE_PARAMETERS order by parameter ASC;
select parameter, value from NLS_SESSION_PARAMETERS order by parameter ASC;
alter pluggable database HO_PDB save state;



ho mkdir -p /u02/app/oracle/oradata/ORCLCDB/HO_PDB/datafile/SVIL_HO_PDB_TABLES
ho mkdir -p /u02/app/oracle/oradata/ORCLCDB/HO_PDB/datafile/SVIL_HO_PDB_INDEXES
ho chmod  750 -R /u02/app/oracle/oradata/ORCLCDB/HO_PDB
REM Compress tablespace so that all tables created on it will hol
REM DEFAULT COMPRESS enables only BASIC compression: data is compressed when loaded with SQL Loader but not when tow is updated/inserted with DML
REM DEFAULT COMPRESS FOR OLTP enables Oracle OLTP compression: data is compressed also in DML statements (however this incurs an extra licensing cost …)
REM The OLTP compression doesn’t immediately compress data as it is inserted or updated in a table. Rather the compression occurs in a batch mode when the degree of change within the block reaches a certain threshold. 
REM When the threshold is reached, all of the uncompressed rows are compressed at the same time. The threshold at which compression occurs is determined by an internal algorithm (over which you have no control).
create tablespace TSD_HO_DEV_TABLES datafile '/u02/app/oracle/oradata/ORCLCDB/HO_PDB/datafile/SVIL_HO_PDB_TABLES/tsd_ho_dev_tables.dbf' size 3G DEFAULT COMPRESS FOR OLTP;
create tablespace TSD_HO_DEV_INDEXES datafile '/u02/app/oracle/oradata/ORCLCDB/HO_PDB/datafile/SVIL_HO_PDB_INDEXES/tsd_ho_dev_indexes.dbf' size 500M DEFAULT COMPRESS FOR OLTP;
REM AFTER SETTING NLS_LENGTH_SEMANTICS  = 'CHAR'; WE NOW USE MUCH MORE SPACE AND NEEDED TO ADD AN ADDITIONAL DATA FILE, NOT NEEDED AFTER COMPRESSING DATA
REM ALTER TABLESPACE TSD_HO_DEV_TABLES ADD DATAFILE '/app/oracle/oradata/orcl/HO_PDB/datafile/SVIL_HO_PDB_TABLES/tsd_ho_dev_tables2.dbf' size 5G;
ALTER SESSION SET CONTAINER=HO_PDB;
SELECT FILE_NAME, BYTES FROM DBA_DATA_FILES WHERE TABLESPACE_NAME = 'TSD_HO_DEV_TABLES';
SELECT DISTINCT TABLESPACE_NAME,  FILE_NAME, BYTES FROM DBA_DATA_FILES;
SET LINESIZE 150
COLUMN TABLESPACE_NAME FORMAT A30
COLUMN BLOCK_SIZE FORMAT 9999999999
COLUMN STATUS FORMAT A9
COLUMN LOGGING FORMAT A9
COLUMN DEF_TAB_COMPRESSION FORMAT A15
COLUMN COMPRESS_FOR FORMAT A30
SELECT TABLESPACE_NAME, BLOCK_SIZE, STATUS, LOGGING, DEF_TAB_COMPRESSION, COMPRESS_FOR FROM DBA_TABLESPACES ORDER BY 1 ASC;
GRANT DBA, CREATE SESSION, CONNECT TO c##HOadmin;
    exit;
EOF

  if [[ ${dbrelarr[0]} == 12 && ${dbrelarr[1]} > 1 ]] || [[ ${dbrelarr[0]} > 12 ]];
  then
    echo "Reset Database parameters"
    sqlplus / as sysdba 2>&1 <<EOF
      alter system set encrypt_new_tablespaces=ddl scope=both;
      exit;
EOF
  fi
else
  echo "startup database instance"
  sqlplus / as sysdba 2>&1 <<EOF
    startup;
    exit;
EOF
fi

## db network set
# sqlnet.ora
SQLNET_ORA=$TNS_ADMIN/sqlnet.ora
echo "NAME.DIRECTORY_PATH= {TNSNAMES, EZCONNECT, HOSTNAME}" >> $SQLNET_ORA
echo "SQLNET.EXPIRE_TIME = 10" >> $SQLNET_ORA
echo "SSL_VERSION = 1.0" >> $SQLNET_ORA
# listener.ora
LSNR_ORA=$TNS_ADMIN/listener.ora
echo "LISTENER = \
  (DESCRIPTION_LIST = \
    (DESCRIPTION = \
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) \
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521)) \
    ) \
  ) \
\
" >> $LSNR_ORA
echo "DIAG_ADR_ENABLED = off"  >> $LSNR_ORA
echo "SSL_VERSION = 1.0"  >> $LSNR_ORA
# tnsnames.ora
TNS_ORA=$TNS_ADMIN/tnsnames.ora
echo "$DB_SID = \
  (DESCRIPTION = \
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) \
    (CONNECT_DATA = \
      (SERVER = DEDICATED) \
      (SERVICE_NAME = $DB_SID.$DB_DOMAIN) \
    ) \
  ) \
" >> $TNS_ORA
echo "$DB_PDB = \
  (DESCRIPTION = \
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) \
    (CONNECT_DATA = \
      (SERVER = DEDICATED) \
      (SERVICE_NAME = $DB_PDB.$DB_DOMAIN) \
    ) \
  ) \
" >> $TNS_ORA

# start listener
lsnrctl start

# clean
unset DB_PASSWD
history -w
history -c

echo ""
echo "DONE!"

# end