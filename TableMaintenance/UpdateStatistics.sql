/*
 * Script: Update Statistics (SQL Server)
 * Description: Updates statistics for all tables in the current database
 * 
 * This script updates statistics which help the query optimizer make better
 * execution plan decisions. Outdated statistics can lead to poor query performance.
 * 
 * Usage:
 *   - Run this script during maintenance windows
 *   - Use FULLSCAN for more accurate statistics (takes longer)
 *   - Use SAMPLE for faster execution with reasonable accuracy
 * 
 * Options:
 *   - WITH FULLSCAN: Scans all rows (most accurate, slowest)
 *   - WITH SAMPLE n PERCENT: Scans n percent of rows (faster, less accurate)
 *   - WITH RESAMPLE: Uses the most recent sample rate
 * 
 * Warning: This can be resource-intensive on large databases
 */

-- Option 1: Update all statistics with full scan (most accurate but slowest)
EXEC sp_updatestats;

-- Option 2: Update statistics for all tables with sampling (faster)
DECLARE @TableName NVARCHAR(256);
DECLARE @SchemaName NVARCHAR(256);
DECLARE @SQL NVARCHAR(MAX);

DECLARE table_cursor CURSOR FOR
SELECT 
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS table_name
FROM 
    sys.tables
WHERE 
    is_ms_shipped = 0
ORDER BY 
    name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'UPDATE STATISTICS [' + @SchemaName + '].[' + @TableName + '] WITH SAMPLE 50 PERCENT;';
    PRINT 'Updating statistics for: ' + @SchemaName + '.' + @TableName;
    
    BEGIN TRY
        EXEC sp_executesql @SQL;
    END TRY
    BEGIN CATCH
        PRINT 'Error updating statistics for ' + @SchemaName + '.' + @TableName + ': ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

PRINT 'Statistics update completed.';
