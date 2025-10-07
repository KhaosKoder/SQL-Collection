# SQL-Collection

This is just a collection of SQL Scripts (aimed at MS-SQL 2016+). Most of these scripts related to admin/optimization tasks. 
Nothing mind-blowing, just a place to store a bunch of useful stuff with code that is at least marginally trustworthy.

Some of these have obviously been built with the help of an LLM (various) - the main prompt is captured here as well. Feel free to adjust/improve. 

## General tasks
**Immediate Print Loop**   
A quick example of how to use RAISERROR to print immediately to the output window without buffering. 
This is useful during testing to immediately see results. 

## Physcial DB Configuration

**Extract Data Disk Mappings**   
This script extracts the DatabaseName, logical name of your main datafile and physical path and filename for the mdf file for all (user) databases  on a server.

## Compression 
**Generate Compress Statements for Database**   
This script generates PAGE compression commands for uncompressed indexes.

**List databases with no compression**   
Add script to identify and list databases with no compression. Also provides some high level stats on how many items in the db are compressed. 

**Monitor all DBCC Shrinkfile operations**   
Add script to monitor DBCC Shrinkfile operations continuously until the operations are complete. 

