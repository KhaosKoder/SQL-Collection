/*
 * Script: Find Unused Indexes (SQL Server)
 * Description: Identifies indexes that are not being used and may be candidates for removal
 * 
 * This script finds indexes that have not been used for seeks, scans, or lookups
 * but have been updated. These indexes consume resources during INSERT/UPDATE/DELETE
 * operations without providing query performance benefits.
 * 
 * Usage:
 *   - Run this query to identify unused indexes
 *   - Review the user_updates column to see maintenance overhead
 *   - Consider dropping indexes with 0 reads but high updates
 * 
 * Warning: 
 *   - Statistics are reset on SQL Server restart
 *   - Verify the last_restart_date to ensure you have sufficient data
 *   - Never drop Primary Key or Unique constraint indexes
 */

SELECT 
    DB_NAME() AS database_name,
    OBJECT_NAME(s.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    ISNULL(user_seeks, 0) AS user_seeks,
    ISNULL(user_scans, 0) AS user_scans,
    ISNULL(user_lookups, 0) AS user_lookups,
    ISNULL(user_updates, 0) AS user_updates,
    (SELECT create_date FROM sys.databases WHERE name = DB_NAME()) AS database_create_date,
    'DROP INDEX [' + i.name + '] ON [' + SCHEMA_NAME(o.schema_id) + '].[' + OBJECT_NAME(s.object_id) + ']' AS drop_statement
FROM 
    sys.dm_db_index_usage_stats s
    RIGHT JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
    INNER JOIN sys.objects o ON i.object_id = o.object_id
WHERE 
    s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
    AND i.type_desc <> 'HEAP'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
    AND (ISNULL(user_seeks, 0) + ISNULL(user_scans, 0) + ISNULL(user_lookups, 0)) = 0
    AND user_updates > 0
ORDER BY 
    user_updates DESC;
