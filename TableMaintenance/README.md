# Table Maintenance Scripts

This directory contains SQL scripts for routine table maintenance operations.

## Scripts

### UpdateStatistics.sql
Updates statistics for all tables in the current database to help the query optimizer make better decisions.

**Key Features:**
- Two options: Full scan or sampling
- Iterates through all user tables
- Error handling for individual tables

**When to Use:**
- After bulk data loads
- After significant data changes
- As part of regular maintenance routines

**Recommended Frequency:**
- Critical databases: Daily or after major data changes
- Regular databases: Weekly
- Low-activity databases: Monthly

### TableSizeReport.sql
Provides detailed information about table sizes including data, indexes, and unused space.

**Key Features:**
- Shows row counts
- Breaks down space usage (data, indexes, unused)
- Sorted by total space for easy identification of large tables

**When to Use:**
- Planning capacity and storage
- Identifying tables for archiving
- Monitoring database growth
- Before maintenance operations

### RebuildAllIndexes.sql
Rebuilds all indexes in the current database to eliminate fragmentation and reclaim space.

**Key Features:**
- Configurable ONLINE option
- SORT_IN_TEMPDB option for performance
- Error handling per index
- Progress reporting

**When to Use:**
- During scheduled maintenance windows
- After major data modifications
- When experiencing performance degradation

**Configuration Options:**
- `@OnlineRebuild`: Set to 1 for ONLINE = ON (requires Enterprise Edition)
- `@SortInTempDB`: Set to 1 to use tempdb for sorting

**Important Notes:**
- Resource-intensive operation
- Requires adequate tempdb space
- Can take hours on large databases
- ONLINE option (Enterprise Edition) minimizes blocking

## Maintenance Schedule Recommendations

### Daily
- Critical production databases: Update statistics

### Weekly
- Regular databases: Update statistics
- Review table sizes for growth trends

### Monthly
- Rebuild or reorganize indexes based on fragmentation analysis
- Review and cleanup unused space

## Best Practices

1. Always test in development first
2. Schedule during maintenance windows
3. Monitor tempdb space during operations
4. Keep transaction logs properly sized
5. Have adequate backup before major operations
