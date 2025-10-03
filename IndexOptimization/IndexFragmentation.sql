/*
 * Script: Index Fragmentation Analysis (SQL Server)
 * Description: Analyzes index fragmentation and provides recommendations for maintenance
 * 
 * This script examines index fragmentation levels and suggests whether to
 * REBUILD or REORGANIZE based on Microsoft's recommended thresholds:
 *   - < 10% fragmentation: No action needed
 *   - 10-30% fragmentation: REORGANIZE
 *   - > 30% fragmentation: REBUILD
 * 
 * Usage:
 *   - Run this query to analyze index fragmentation
 *   - Execute the suggested maintenance commands during off-peak hours
 *   - Monitor the page_count to prioritize larger indexes
 * 
 * Parameters:
 *   - @MinFragmentation: Minimum fragmentation % to report (default: 10)
 *   - @MinPageCount: Minimum pages to consider (default: 1000)
 */

DECLARE @MinFragmentation FLOAT = 10.0;
DECLARE @MinPageCount INT = 1000;

SELECT 
    DB_NAME() AS database_name,
    OBJECT_NAME(ips.object_id) AS table_name,
    i.name AS index_name,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    CASE 
        WHEN ips.avg_fragmentation_in_percent < 10 THEN 'No action needed'
        WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 THEN 'REORGANIZE'
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
    END AS recommendation,
    CASE 
        WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 
        THEN 'ALTER INDEX [' + i.name + '] ON [' + SCHEMA_NAME(o.schema_id) + '].[' + OBJECT_NAME(ips.object_id) + '] REORGANIZE;'
        WHEN ips.avg_fragmentation_in_percent > 30 
        THEN 'ALTER INDEX [' + i.name + '] ON [' + SCHEMA_NAME(o.schema_id) + '].[' + OBJECT_NAME(ips.object_id) + '] REBUILD WITH (ONLINE = ON);'
        ELSE NULL
    END AS maintenance_command
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    INNER JOIN sys.objects o ON ips.object_id = o.object_id
WHERE 
    ips.avg_fragmentation_in_percent >= @MinFragmentation
    AND ips.page_count >= @MinPageCount
    AND i.name IS NOT NULL
    AND OBJECTPROPERTY(ips.object_id, 'IsUserTable') = 1
ORDER BY 
    ips.avg_fragmentation_in_percent DESC,
    ips.page_count DESC;
