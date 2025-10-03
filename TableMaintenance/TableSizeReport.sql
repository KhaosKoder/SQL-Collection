/*
 * Script: Table Size Report (SQL Server)
 * Description: Shows the size of all tables including row counts and space usage
 * 
 * This script provides a comprehensive view of table sizes, helping identify
 * tables that may need maintenance, archiving, or optimization.
 * 
 * Output columns:
 *   - TableName: Name of the table
 *   - RowCounts: Number of rows in the table
 *   - TotalSpaceMB: Total space used (data + indexes + unused)
 *   - DataSpaceMB: Space used by data
 *   - IndexSpaceMB: Space used by indexes
 *   - UnusedSpaceMB: Allocated but unused space
 * 
 * Usage:
 *   - Run to identify large tables
 *   - Use to plan capacity and archiving strategies
 *   - Monitor table growth over time
 */

SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    CAST(ROUND((SUM(a.total_pages) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    CAST(ROUND((SUM(a.used_pages) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UsedSpaceMB,
    CAST(ROUND((SUM(a.data_pages) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS DataSpaceMB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
    INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    LEFT JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    TotalSpaceMB DESC;
