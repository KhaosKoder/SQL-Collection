# Index Optimization Scripts

This directory contains SQL scripts for analyzing and optimizing database indexes.

## Scripts

### FindMissingIndexes.sql
Identifies missing indexes that could improve query performance based on SQL Server's missing index DMVs.

**Key Features:**
- Shows potential performance improvement measure
- Generates CREATE INDEX statements
- Filters by minimum impact threshold

**When to Use:**
- After deploying new code or queries
- When experiencing slow query performance
- During regular performance reviews

### FindUnusedIndexes.sql
Identifies indexes that are not being used but consume resources during data modifications.

**Key Features:**
- Shows indexes with zero reads but high updates
- Generates DROP INDEX statements
- Excludes Primary Keys and Unique Constraints

**When to Use:**
- During database cleanup initiatives
- When reducing maintenance overhead
- Before major data loads

**Warning:** Statistics reset on SQL Server restart. Ensure you have enough runtime data.

### IndexFragmentation.sql
Analyzes index fragmentation levels and provides maintenance recommendations.

**Key Features:**
- Shows fragmentation percentage
- Recommends REBUILD or REORGANIZE based on Microsoft best practices
- Generates maintenance commands

**When to Use:**
- During scheduled maintenance windows
- When queries are performing slower than usual
- As part of regular maintenance routines

**Best Practices:**
- Run during off-peak hours
- Prioritize larger indexes
- Consider ONLINE option for production systems (Enterprise Edition)

## Fragmentation Thresholds

- **< 10% fragmentation:** No action needed
- **10-30% fragmentation:** REORGANIZE (online operation)
- **> 30% fragmentation:** REBUILD (consider ONLINE option)

## Notes

All scripts are designed for SQL Server. Modify as needed for other database platforms.
