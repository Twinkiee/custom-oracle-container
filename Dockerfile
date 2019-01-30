FROM container-registry.oracle.com/database/enterprise:12.2.0.1-slim

COPY ./configDBora.sh /home/oracle/setup/configDBora.sh
## COPY ./dockerInit.sh /home/oracle/setup/dockerInit-b.sh
## CMD /bin/bash /home/oracle/setup/dockerInit-b.sh
## USER root
## RUN chmod -R 777 /home/oracle
## COPY ./resire-db-entrypoint.sh /
## CMD /bin/bash /resire-db-entrypoint.sh



## SHELL ["/bin/bash", "-c"]
## RUN ["/bin/bash"]
## CMD ["echo", "$PATH"]
## RUN ["/u01/app/oracle/product/12.2.0/dbhome_1/bin/sqlplus", "sys/Oradoc_db1@ORCLCDB as sysdba"]
## RUN sqlplus "sys/Oradoc_db1@ORCLCDB as sysdba"
## RUN CREATE USER c##HOadmin IDENTIFIED BY oracle;
## RUN GRANT create session, connect, dba TO c##HOadmin CONTAINER=ALL;
## RUN CREATE PLUGGABLE DATABASE HO_PDB ADMIN USER HOadmin IDENTIFIED BY Kraken96 CREATE_FILE_DEST='/ORCL/u02/app/oracle/oradata/ORCLCDB/HO_PDB';
## RUN ALTER SESSION SET CONTAINER=HO_PDB;
## RUN alter pluggable database HO_PDB open services=all;
## RUN GRANT connect, resource, pdb_dba, alter database TO HOadmin;
## RUN alter system set NLS_LANGUAGE = 'ENGLISH' scope = SPFILE;
## RUN alter system set NLS_COMP = 'LINGUISTIC' scope = SPFILE;
## RUN alter system set NLS_SORT = 'EBCDIC' scope = SPFILE;
## RUN alter system set NLS_LENGTH_SEMANTICS  = 'CHAR'  scope = SPFILE;
## RUN set linesize 100
## RUN COLUMN parameter FORMAT A40
## RUN COLUMN value FORMAT A40
## RUN alter pluggable database HO_PDB save state;
## RUN ho mkdir -p /app/oracle/oradata/orcl/HO_PDB/datafile/SVIL_HO_PDB_TABLES
## RUN ho mkdir -p /app/oracle/oradata/orcl/HO_PDB/datafile/SVIL_HO_PDB_INDEXES
## RUN ho chmod  750 -R /app/oracle/oradata/orcl/HO_PDB
## RUN create tablespace TSD_HO_DEV_TABLES datafile '/app/oracle/oradata/orcl/HO_PDB/datafile/SVIL_HO_PDB_TABLES/tsd_ho_dev_tables.dbf' size 3G DEFAULT COMPRESS FOR OLTP;
## RUN create tablespace TSD_HO_DEV_INDEXES datafile '/app/oracle/oradata/orcl/HO_PDB/datafile/SVIL_HO_PDB_INDEXES/tsd_ho_dev_indexes.dbf' size 500M DEFAULT COMPRESS FOR OLTP;
## RUN ALTER SESSION SET CONTAINER=HO_PDB;
## RUN SET LINESIZE 150
## RUN COLUMN TABLESPACE_NAME FORMAT A30
## RUN COLUMN BLOCK_SIZE FORMAT 9999999999
## RUN COLUMN STATUS FORMAT A9
## RUN COLUMN LOGGING FORMAT A9
## RUN COLUMN DEF_TAB_COMPRESSION FORMAT A15
## RUN COLUMN COMPRESS_FOR FORMAT A30
## RUN SELECT TABLESPACE_NAME, BLOCK_SIZE, STATUS, LOGGING, DEF_TAB_COMPRESSION, COMPRESS_FOR FROM DBA_TABLESPACES ORDER BY 1 ASC;
## RUN GRANT DBA, CREATE SESSION, CONNECT TO c##HOadmin;