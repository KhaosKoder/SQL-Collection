# Backup & Restore Scripts

This directory contains SQL scripts for managing database backups and restores.

## Scripts

### BackupHistory.sql
Shows comprehensive backup history for all databases.

**Key Features:**
- Lists all backups from the last 30 days
- Shows backup types (Full, Differential, Log)
- Displays backup sizes and compression ratios
- Summary view of last backup per type per database

**When to Use:**
- Verify backup schedules are working
- Audit backup compliance
- Plan backup retention strategies
- Troubleshoot backup failures

**What to Look For:**
- Databases without recent backups
- Failed backups
- Backup size trends
- Missing log backups for FULL recovery model databases

### FullBackupTemplate.sql
Template for performing full database backups.

**Key Features:**
- Configurable compression
- Optional backup verification
- Timestamped backup files
- Checksum validation
- Progress reporting

**Configuration:**
- `@DatabaseName`: Database to backup
- `@BackupPath`: Location for backup file
- `@UseCompression`: Enable/disable compression
- `@Verify`: Enable/disable verification

**Best Practices:**
- Use compression to save space (slight CPU overhead)
- Always verify critical backups
- Test restore periodically
- Monitor backup file sizes

### LogBackupTemplate.sql
Template for transaction log backups.

**Key Features:**
- Validates recovery model
- Configurable compression
- Timestamped backup files
- Shows log space usage after backup

**Configuration:**
- `@DatabaseName`: Database to backup
- `@BackupPath`: Location for backup file
- `@UseCompression`: Enable/disable compression

**Requirements:**
- Database must be in FULL or BULK_LOGGED recovery model
- At least one full backup must exist

**Important Notes:**
- Log backups truncate the inactive portion of the transaction log
- Required for point-in-time recovery
- Critical for minimizing data loss

## Backup Strategy Recommendations

### Full Backups
**Frequency:**
- Critical databases: Daily
- Standard databases: Weekly
- Development databases: Weekly or as needed

**Best Practices:**
- Schedule during low-activity periods
- Verify backups regularly
- Test restores periodically
- Monitor backup duration trends

### Differential Backups
**Use Case:** 
- Reduce restore time compared to full + log backups
- Faster than full backups

**Frequency:**
- If full backups are weekly: Daily differentials
- If full backups are daily: Not typically needed

### Transaction Log Backups
**Frequency (FULL recovery model):**
- Critical databases: Every 15-30 minutes
- Standard databases: Every 1-4 hours
- Low-activity databases: Every 4-12 hours

**Why Important:**
- Enables point-in-time recovery
- Prevents transaction log from growing indefinitely
- Minimizes potential data loss

## Recovery Models

### SIMPLE
- No log backups possible
- Point-in-time recovery not available
- Log file automatically truncated
- Use for: Development, non-critical data

### FULL
- Requires regular log backups
- Enables point-in-time recovery
- Use for: Production databases

### BULK_LOGGED
- Similar to FULL but with minimal logging for bulk operations
- Log backups required
- Point-in-time recovery available (with limitations)
- Use for: Large bulk operations

## Backup Checklist

### Daily Tasks
- [ ] Verify full backups completed successfully
- [ ] Verify log backups are running
- [ ] Check for backup failures
- [ ] Monitor backup file sizes

### Weekly Tasks
- [ ] Review backup history
- [ ] Verify backup file retention
- [ ] Check available disk space
- [ ] Test restore of critical databases

### Monthly Tasks
- [ ] Full restore test of critical databases
- [ ] Review backup strategy
- [ ] Verify offsite backup copy exists
- [ ] Update documentation

## Backup Verification

**Why Verify:**
- Ensure backup file is not corrupt
- Confirm backup can be used for restore
- Meet compliance requirements

**How to Verify:**
```sql
RESTORE VERIFYONLY FROM DISK = 'C:\Backups\Database.bak' WITH CHECKSUM;
```

## Disaster Recovery Considerations

1. **Offsite Storage:** Keep copies in different physical locations
2. **Encryption:** Encrypt sensitive backup files
3. **Retention:** Follow organizational and compliance requirements
4. **Documentation:** Maintain restore procedures
5. **Testing:** Regularly test restore procedures
6. **RTO/RPO:** Understand recovery time and point objectives

## Common Backup Errors

| Error | Cause | Solution |
|-------|-------|----------|
| Insufficient disk space | Backup drive full | Free space or change backup location |
| Cannot open backup device | Path doesn't exist | Verify path and permissions |
| Backup device write error | Disk issue | Check disk health |
| Backup checksum error | Corruption | Investigate database integrity |

## Script Modifications

All scripts use:
- `WITH INIT`: Overwrites existing backup file
- `WITH CHECKSUM`: Validates backup integrity
- `WITH COMPRESSION`: Reduces backup size (SQL Server 2008+)

Modify these options based on your needs.
