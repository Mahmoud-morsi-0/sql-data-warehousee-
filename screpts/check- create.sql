/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/



--SELECT 1 FROM / :  is just a dummy value. The important part is that the SELECT returns any row at all
--SINGLE_USERSINGLE_USER /  : Before you drop a database, you need to make sure no one is using it. This line ensures:
use master; 


		IF EXISTS (SELECT 1 FROM sys.databases  WHERE name ='DataWarehouse')
		BEGIN 
		alter database  DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		 drop database DataWarehouse
		 end 
		 go 


create database DataWarehouse;
go

use DataWarehouse;
go

create schema bronze;
go
create schema silver;
go
create schema gold;

 

