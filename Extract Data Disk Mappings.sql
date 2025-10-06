--------------------------------------------------------------------------------------------------------------------------------------
-- Extract Data Disk Mappings.
-- This script extracts each database and which disk it lives on for each lookups.
-- This script focusses only on the main mdf file for each db.
--------------------------------------------------------------------------------------------------------------------------------------

SET NOCOUNT ON;

DECLARE @DBFiles TABLE (
    DBName SYSNAME,
    LogicalName SYSNAME,
    PhysicalName NVARCHAR(260)
);

INSERT INTO @DBFiles (DBName, LogicalName, PhysicalName)
SELECT
    d.name AS DBName,
    mf.name AS LogicalName,
    mf.physical_name AS PhysicalName
FROM sys.master_files mf
JOIN sys.databases d ON mf.database_id = d.database_id
WHERE d.name NOT IN ('master', 'model', 'msdb', 'tempdb')
  AND d.state_desc = 'ONLINE'
  AND mf.type_desc = 'ROWS'
  AND RIGHT(mf.physical_name, 4) = '.mdf';

SELECT
    DBName,
    LogicalName,
    PhysicalName,
    TRY_CAST(
        REVERSE(
            LEFT(
                REVERSE(DBName),
                PATINDEX('%[^0-9]%', REVERSE(DBName) + 'X') - 1
            )
        ) AS INT
    ) AS DatabaseNumber,
    TRY_CAST(
        SUBSTRING(
            PhysicalName,
            CHARINDEX('NED Data ', PhysicalName) + 9,
            PATINDEX('%[^0-9]%', SUBSTRING(PhysicalName, CHARINDEX('NED Data ', PhysicalName) + 9, 10) + 'X') - 1
        ) AS INT
    ) AS DiskNumber
FROM @DBFiles
ORDER BY DBName;
