/*
 * Script: Database Backup History (SQL Server)
 * Description: Shows the backup history for all databases
 * 
 * This script queries the msdb database to show when databases were last backed up
 * and what type of backup was performed.
 * 
 * Backup types:
 *   - D: Full database backup
 *   - I: Differential database backup
 *   - L: Transaction log backup
 * 
 * Output columns:
 *   - database_name: Name of the database
 *   - backup_type: Type of backup (Full, Differential, Log)
 *   - backup_start_date: When the backup started
 *   - backup_finish_date: When the backup completed
 *   - backup_size_mb: Size of the backup in MB
 *   - compressed_backup_size_mb: Compressed size (if compression was used)
 *   - recovery_model: Database recovery model
 * 
 * Usage:
 *   - Run to verify backup schedules are working
 *   - Identify databases that haven't been backed up recently
 *   - Monitor backup sizes for capacity planning
 */

SELECT 
    d.name AS database_name,
    d.recovery_model_desc AS recovery_model,
    CASE bs.type
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Log'
    END AS backup_type,
    bs.backup_start_date,
    bs.backup_finish_date,
    DATEDIFF(MINUTE, bs.backup_start_date, bs.backup_finish_date) AS duration_minutes,
    CAST(bs.backup_size / 1024 / 1024 AS DECIMAL(10, 2)) AS backup_size_mb,
    CAST(bs.compressed_backup_size / 1024 / 1024 AS DECIMAL(10, 2)) AS compressed_backup_size_mb,
    bmf.physical_device_name AS backup_location,
    bs.user_name AS backup_user,
    bs.server_name,
    bs.machine_name
FROM 
    msdb.dbo.backupset bs
    INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
    INNER JOIN sys.databases d ON bs.database_name = d.name
WHERE 
    bs.backup_finish_date >= DATEADD(DAY, -30, GETDATE())  -- Last 30 days
ORDER BY 
    d.name,
    bs.backup_finish_date DESC;

-- Summary: Last backup of each type per database
SELECT 
    d.name AS database_name,
    d.recovery_model_desc AS recovery_model,
    d.state_desc AS database_state,
    MAX(CASE WHEN bs.type = 'D' THEN bs.backup_finish_date END) AS last_full_backup,
    MAX(CASE WHEN bs.type = 'I' THEN bs.backup_finish_date END) AS last_differential_backup,
    MAX(CASE WHEN bs.type = 'L' THEN bs.backup_finish_date END) AS last_log_backup,
    DATEDIFF(DAY, MAX(CASE WHEN bs.type = 'D' THEN bs.backup_finish_date END), GETDATE()) AS days_since_full_backup
FROM 
    sys.databases d
    LEFT JOIN msdb.dbo.backupset bs ON d.name = bs.database_name
WHERE 
    d.database_id > 4  -- Exclude system databases
GROUP BY 
    d.name,
    d.recovery_model_desc,
    d.state_desc
ORDER BY 
    days_since_full_backup DESC;
