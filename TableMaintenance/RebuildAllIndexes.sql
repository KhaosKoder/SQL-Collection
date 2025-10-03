/*
 * Script: Rebuild All Indexes (SQL Server)
 * Description: Rebuilds all indexes in the current database to eliminate fragmentation
 * 
 * This script rebuilds all indexes which:
 *   - Removes fragmentation
 *   - Reclaims unused space
 *   - Updates statistics
 * 
 * Usage:
 *   - Run during maintenance windows
 *   - Use ONLINE = ON for Enterprise Edition to minimize blocking
 *   - Monitor tempdb usage as rebuilds use temporary space
 * 
 * Options:
 *   - ONLINE = ON: Allows concurrent access (Enterprise Edition only)
 *   - ONLINE = OFF: Faster but locks tables
 *   - SORT_IN_TEMPDB = ON: Uses tempdb for sorting (can improve performance)
 * 
 * Warning: 
 *   - This is a resource-intensive operation
 *   - Can take several hours on large databases
 *   - Requires adequate tempdb space
 */

-- Set options
DECLARE @OnlineRebuild BIT = 1; -- 1 for ONLINE = ON, 0 for ONLINE = OFF
DECLARE @SortInTempDB BIT = 1;  -- 1 to use tempdb for sorting

DECLARE @SchemaName NVARCHAR(256);
DECLARE @TableName NVARCHAR(256);
DECLARE @IndexName NVARCHAR(256);
DECLARE @SQL NVARCHAR(MAX);

DECLARE index_cursor CURSOR FOR
SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    i.name AS index_name
FROM 
    sys.indexes i
    INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE 
    i.type > 0  -- Exclude heaps
    AND i.name IS NOT NULL
    AND t.is_ms_shipped = 0
ORDER BY 
    t.name, i.name;

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @SchemaName, @TableName, @IndexName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + '] REBUILD';
    
    -- Add options
    SET @SQL = @SQL + ' WITH (';
    
    IF @OnlineRebuild = 1
        SET @SQL = @SQL + 'ONLINE = ON, ';
    
    IF @SortInTempDB = 1
        SET @SQL = @SQL + 'SORT_IN_TEMPDB = ON';
    
    -- Remove trailing comma if present
    IF RIGHT(@SQL, 2) = ', '
        SET @SQL = LEFT(@SQL, LEN(@SQL) - 2);
    
    SET @SQL = @SQL + ');';
    
    PRINT 'Rebuilding index: ' + @SchemaName + '.' + @TableName + '.' + @IndexName;
    
    BEGIN TRY
        EXEC sp_executesql @SQL;
        PRINT 'Success';
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM index_cursor INTO @SchemaName, @TableName, @IndexName;
END

CLOSE index_cursor;
DEALLOCATE index_cursor;

PRINT 'Index rebuild completed.';
