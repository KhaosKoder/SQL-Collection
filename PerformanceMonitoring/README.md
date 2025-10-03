# Performance Monitoring Scripts

This directory contains SQL scripts for monitoring and analyzing database performance.

## Scripts

### TopCPUQueries.sql
Identifies the queries consuming the most CPU time.

**Key Features:**
- Shows total and average CPU time per query
- Includes execution counts
- Displays actual query text and execution plans

**When to Use:**
- When experiencing high CPU usage
- During performance troubleshooting
- For regular performance reviews

**What to Look For:**
- High avg_cpu_time with high execution_count
- Queries that can benefit from indexes or rewrites

### LongRunningQueries.sql
Shows currently executing queries and how long they've been running.

**Key Features:**
- Real-time view of active queries
- Shows blocking session information
- Displays wait types and resources
- Includes user and application context

**When to Use:**
- When users report slow performance
- To identify stuck or runaway queries
- During incident response

**Key Columns:**
- `duration_seconds`: How long the query has been running
- `blocking_session_id`: If non-zero, which session is blocking this query
- `wait_type`: What resource the query is waiting for

### BlockingQueries.sql
Identifies blocking chains and shows which queries are causing others to wait.

**Key Features:**
- Shows blocker and blocked session details
- Displays blocking hierarchy
- Identifies head blockers (sessions blocking multiple others)
- Provides query text for both blocker and blocked

**When to Use:**
- When experiencing blocking issues
- During high-concurrency periods
- To identify locking problems

**How to Use:**
1. Run to identify blocking chains
2. Review the head blocker's query
3. Consider:
   - Optimizing the blocking query
   - Adding indexes
   - Reducing transaction scope
   - In emergencies: KILL the blocking session

### WaitStatistics.sql
Analyzes what the database is waiting on to identify performance bottlenecks.

**Key Features:**
- Shows top wait types by time
- Filters out benign waits
- Calculates percentages and averages
- Shows SQL Server uptime for context

**When to Use:**
- During performance analysis
- To identify system bottlenecks
- For capacity planning

**Common Wait Types:**

| Wait Type | Meaning | Action |
|-----------|---------|--------|
| PAGEIOLATCH_* | Disk I/O bottleneck | Add faster storage, optimize queries |
| LCK_* | Locking/blocking | Review transaction scope, add indexes |
| CXPACKET | Parallelism issues | Review MAXDOP, update statistics |
| SOS_SCHEDULER_YIELD | CPU pressure | Add CPU, optimize queries |
| WRITELOG | Log file I/O | Faster log disk, reduce transactions |

## Monitoring Best Practices

### Real-Time Monitoring
1. Start with LongRunningQueries.sql for active issues
2. Check BlockingQueries.sql if blocking is suspected
3. Review current wait types

### Historical Analysis
1. Review TopCPUQueries.sql for resource-intensive queries
2. Analyze WaitStatistics.sql for systemic issues
3. Compare metrics over time

### Response to Issues
1. **Immediate**: Identify and address blocking or long-running queries
2. **Short-term**: Optimize specific problematic queries
3. **Long-term**: Address systemic issues (storage, CPU, memory)

## Important Notes

- Statistics in DMVs are cleared on SQL Server restart
- Always check server uptime to understand the time window
- DMV data represents historical activity, not just current
- Some waits are normal - focus on patterns and high percentages

## Integration with Monitoring Tools

These scripts can be:
- Scheduled as SQL Agent jobs
- Integrated into monitoring solutions
- Used for ad-hoc troubleshooting
- Modified for specific environments
