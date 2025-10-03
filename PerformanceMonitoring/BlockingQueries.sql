/*
 * Script: Blocking Queries (SQL Server)
 * Description: Identifies blocking chains and what queries are being blocked
 * 
 * This script shows blocking relationships between sessions, helping identify
 * which queries are causing others to wait.
 * 
 * Output shows:
 *   - The head blocker (session causing the blocking)
 *   - Blocked sessions and what they're waiting for
 *   - The queries being executed by both blocker and blocked sessions
 * 
 * Usage:
 *   - Run when experiencing blocking issues
 *   - Identify the head blocker session_id
 *   - Review the blocker's query to understand the cause
 *   - Consider killing the blocker session if necessary: KILL <session_id>
 * 
 * Warning: Be careful when killing sessions - ensure you understand the impact
 */

-- Show blocking hierarchy
SELECT 
    blocking.session_id AS blocking_session_id,
    blocking.status AS blocking_status,
    blocking.command AS blocking_command,
    DB_NAME(blocking.database_id) AS blocking_database,
    blocking_text.text AS blocking_query_text,
    blocked.session_id AS blocked_session_id,
    blocked.status AS blocked_status,
    blocked.command AS blocked_command,
    blocked.wait_type,
    blocked.wait_time AS wait_time_ms,
    blocked.wait_resource,
    DB_NAME(blocked.database_id) AS blocked_database,
    blocked_text.text AS blocked_query_text,
    blocking_session.host_name AS blocking_host,
    blocking_session.program_name AS blocking_program,
    blocking_session.login_name AS blocking_login,
    blocked_session.host_name AS blocked_host,
    blocked_session.program_name AS blocked_program,
    blocked_session.login_name AS blocked_login
FROM 
    sys.dm_exec_requests blocked
    INNER JOIN sys.dm_exec_requests blocking ON blocked.blocking_session_id = blocking.session_id
    INNER JOIN sys.dm_exec_sessions blocking_session ON blocking.session_id = blocking_session.session_id
    INNER JOIN sys.dm_exec_sessions blocked_session ON blocked.session_id = blocked_session.session_id
    CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) blocking_text
    CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blocked_text
WHERE 
    blocked.blocking_session_id <> 0
ORDER BY 
    blocked.wait_time DESC;

-- Show head blockers (sessions blocking others but not blocked themselves)
SELECT DISTINCT
    r.session_id AS head_blocker_session_id,
    r.status,
    r.command,
    r.start_time,
    DATEDIFF(SECOND, r.start_time, GETDATE()) AS duration_seconds,
    DB_NAME(r.database_id) AS database_name,
    s.host_name,
    s.program_name,
    s.login_name,
    st.text AS query_text,
    COUNT(DISTINCT blocked.session_id) AS number_of_blocked_sessions
FROM 
    sys.dm_exec_requests r
    INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
    INNER JOIN sys.dm_exec_requests blocked ON r.session_id = blocked.blocking_session_id
WHERE 
    r.blocking_session_id = 0  -- Not blocked by anyone
GROUP BY
    r.session_id, r.status, r.command, r.start_time, r.database_id,
    s.host_name, s.program_name, s.login_name, st.text
ORDER BY 
    number_of_blocked_sessions DESC;
