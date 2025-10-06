SET NOCOUNT ON;

-- =============================================
-- Parameters and Table Variable Declaration
-- =============================================
DECLARE @DBFiles TABLE (
    DBName SYSNAME,
    LogicalName SYSNAME,
    PhysicalName NVARCHAR(260),
    DatabaseNumber INT,
    DiskNumber INT
);

-- =============================================
-- Populate Table Variable with All Columns
-- =============================================
INSERT INTO @DBFiles (DBName, LogicalName, PhysicalName, DatabaseNumber, DiskNumber)
SELECT
    d.name AS DBName,
    mf.name AS LogicalName,
    mf.physical_name AS PhysicalName,
    TRY_CAST(
        REVERSE(
            LEFT(
                REVERSE(d.name),
                PATINDEX('%[^0-9]%', REVERSE(d.name) + 'X') - 1
            )
        ) AS INT
    ) AS DatabaseNumber,
    TRY_CAST(
        SUBSTRING(
            mf.physical_name,
            CHARINDEX('NED Data ', mf.physical_name) + 9,
            PATINDEX('%[^0-9]%', SUBSTRING(mf.physical_name, CHARINDEX('NED Data ', mf.physical_name) + 9, 10) + 'X') - 1
        ) AS INT
    ) AS DiskNumber
FROM sys.master_files mf
JOIN sys.databases d ON mf.database_id = d.database_id
WHERE d.name NOT IN ('master', 'model', 'msdb', 'tempdb')
  AND d.state_desc = 'ONLINE'
  AND mf.type_desc = 'ROWS'
  AND RIGHT(mf.physical_name, 4) = '.mdf';

-- =============================================
-- Example Queries
-- =============================================

-- Filter by DiskNumber
SELECT *
FROM @DBFiles
WHERE DiskNumber = 7
ORDER BY DBName;



