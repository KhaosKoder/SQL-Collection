/*
 * Script: Wait Statistics (SQL Server)
 * Description: Shows what the database is waiting on
 * 
 * This script analyzes wait statistics to help identify performance bottlenecks.
 * Different wait types indicate different issues:
 *   - PAGEIOLATCH_*: Disk I/O bottleneck
 *   - LCK_*: Locking/blocking issues
 *   - CXPACKET: Parallelism issues
 *   - SOS_SCHEDULER_YIELD: CPU pressure
 * 
 * Output columns:
 *   - wait_type: Type of wait
 *   - wait_time_seconds: Total time spent waiting
 *   - wait_count: Number of waits
 *   - percentage: Percentage of total wait time
 *   - avg_wait_time_ms: Average wait time
 * 
 * Usage:
 *   - Run to understand performance bottlenecks
 *   - Focus on wait types with high percentages
 *   - Research specific wait types for optimization strategies
 * 
 * Note: Wait stats accumulate since last SQL Server restart or manual reset
 */

WITH Waits AS
(
    SELECT 
        wait_type,
        wait_time_ms / 1000.0 AS wait_time_seconds,
        waiting_tasks_count AS wait_count,
        100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS percentage,
        (wait_time_ms - signal_wait_time_ms) / 1000.0 AS resource_wait_seconds,
        signal_wait_time_ms / 1000.0 AS signal_wait_seconds
    FROM 
        sys.dm_os_wait_stats
    WHERE 
        wait_type NOT IN (
            -- Filter out benign wait types
            'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
            'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
            'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT',
            'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT',
            'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
            'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
            'ONDEMAND_TASK_QUEUE', 'BROKER_EVENTHANDLER', 'SLEEP_BPOOL_FLUSH',
            'DIRTY_PAGE_POLL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'SP_SERVER_DIAGNOSTICS_SLEEP'
        )
        AND waiting_tasks_count > 0
)
SELECT TOP 25
    wait_type,
    CAST(wait_time_seconds AS DECIMAL(12, 2)) AS wait_time_seconds,
    wait_count,
    CAST(percentage AS DECIMAL(5, 2)) AS percentage,
    CAST((wait_time_seconds / wait_count) * 1000 AS DECIMAL(12, 2)) AS avg_wait_time_ms,
    CAST(resource_wait_seconds AS DECIMAL(12, 2)) AS resource_wait_seconds,
    CAST(signal_wait_seconds AS DECIMAL(12, 2)) AS signal_wait_seconds
FROM 
    Waits
ORDER BY 
    wait_time_seconds DESC;

-- Get SQL Server uptime to understand the time window
SELECT 
    sqlserver_start_time,
    DATEDIFF(DAY, sqlserver_start_time, GETDATE()) AS days_uptime,
    DATEDIFF(HOUR, sqlserver_start_time, GETDATE()) % 24 AS hours_uptime
FROM 
    sys.dm_os_sys_info;
