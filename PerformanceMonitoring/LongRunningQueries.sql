/*
 * Script: Long Running Queries (SQL Server)
 * Description: Shows currently executing queries and their duration
 * 
 * This script identifies queries that are currently running and shows how long
 * they've been executing. Useful for finding blocking queries or long-running operations.
 * 
 * Output columns:
 *   - session_id: The session ID executing the query
 *   - status: Current status (running, suspended, etc.)
 *   - command: Type of command being executed
 *   - duration_seconds: How long the query has been running
 *   - cpu_time_ms: CPU time used
 *   - blocking_session_id: If blocked, which session is blocking
 *   - wait_type: What the query is waiting for
 *   - query_text: The actual SQL being executed
 * 
 * Usage:
 *   - Run to identify long-running queries
 *   - Use blocking_session_id to identify blocking chains
 *   - Check wait_type to understand what queries are waiting for
 * 
 * Note: Shows only currently executing queries
 */

SELECT 
    r.session_id,
    r.status,
    r.command,
    r.start_time,
    DATEDIFF(SECOND, r.start_time, GETDATE()) AS duration_seconds,
    r.cpu_time AS cpu_time_ms,
    r.total_elapsed_time AS total_elapsed_time_ms,
    r.reads,
    r.writes,
    r.logical_reads,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time AS wait_time_ms,
    r.last_wait_type,
    r.wait_resource,
    DB_NAME(r.database_id) AS database_name,
    s.host_name,
    s.program_name,
    s.login_name,
    s.login_time,
    SUBSTRING(st.text, (r.statement_start_offset/2) + 1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) AS query_text,
    qp.query_plan
FROM 
    sys.dm_exec_requests r
    INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
    CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp
WHERE 
    r.session_id <> @@SPID  -- Exclude this query itself
    AND s.is_user_process = 1  -- Only user processes
ORDER BY 
    r.total_elapsed_time DESC;
