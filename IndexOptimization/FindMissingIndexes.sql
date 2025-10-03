/*
 * Script: Find Missing Indexes (SQL Server)
 * Description: Identifies missing indexes that could improve query performance
 * 
 * This script queries the SQL Server DMVs (Dynamic Management Views) to find
 * indexes that the query optimizer has identified as potentially beneficial.
 * 
 * Usage:
 *   - Run this query to get a list of missing indexes
 *   - Review the improvement_measure and avg_user_impact columns
 *   - Consider creating indexes with high improvement measures
 * 
 * Warning: Don't create all suggested indexes blindly. Each index has maintenance overhead.
 */

SELECT 
    CONVERT(DECIMAL(18,2), migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvement_measure,
    CONVERT(DECIMAL(18,2), migs.avg_user_impact) AS avg_user_impact,
    migs.user_seeks,
    migs.user_scans,
    DB_NAME(mid.database_id) AS database_name,
    OBJECT_NAME(mid.object_id, mid.database_id) AS table_name,
    'CREATE INDEX IX_' + 
        OBJECT_NAME(mid.object_id, mid.database_id) + '_' +
        REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '') +
        CASE 
            WHEN mid.inequality_columns IS NOT NULL 
            THEN '_' + REPLACE(REPLACE(REPLACE(mid.inequality_columns, ', ', '_'), '[', ''), ']', '')
            ELSE '' 
        END + 
        ' ON ' + mid.statement + 
        ' (' + ISNULL(mid.equality_columns, '') +
        CASE 
            WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL 
            THEN ',' 
            ELSE '' 
        END +
        ISNULL(mid.inequality_columns, '') + ')' +
        ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
    migs.last_user_seek,
    migs.last_user_scan
FROM 
    sys.dm_db_missing_index_groups mig
    INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
    INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE 
    migs.avg_user_impact > 10 -- Only show indexes with potential impact > 10%
    AND mid.database_id = DB_ID() -- Current database only
ORDER BY 
    improvement_measure DESC;
