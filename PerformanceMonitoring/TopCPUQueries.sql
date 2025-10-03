/*
 * Script: Top CPU Consuming Queries (SQL Server)
 * Description: Identifies queries consuming the most CPU time
 * 
 * This script helps identify queries that are CPU-intensive and may need
 * optimization. It shows both individual execution stats and aggregate stats.
 * 
 * Output columns:
 *   - total_worker_time: Total CPU time in microseconds
 *   - execution_count: Number of times the query has executed
 *   - avg_worker_time: Average CPU time per execution
 *   - query_text: The actual SQL query text
 *   - creation_time: When the plan was created
 *   - last_execution_time: When the query was last executed
 * 
 * Usage:
 *   - Run to identify CPU-intensive queries
 *   - Focus on queries with high avg_worker_time and high execution_count
 *   - Review query_text to identify optimization opportunities
 * 
 * Note: Statistics are cleared on SQL Server restart
 */

SELECT TOP 50
    qs.total_worker_time / 1000 AS total_cpu_time_ms,
    qs.execution_count,
    (qs.total_worker_time / 1000) / qs.execution_count AS avg_cpu_time_ms,
    qs.total_elapsed_time / 1000 AS total_elapsed_time_ms,
    (qs.total_elapsed_time / 1000) / qs.execution_count AS avg_elapsed_time_ms,
    qs.total_logical_reads,
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
    qs.total_physical_reads,
    qs.creation_time,
    qs.last_execution_time,
    SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS query_text,
    DB_NAME(st.dbid) AS database_name,
    OBJECT_NAME(st.objectid, st.dbid) AS object_name,
    qp.query_plan
FROM 
    sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE 
    st.dbid IS NOT NULL
ORDER BY 
    qs.total_worker_time DESC;
