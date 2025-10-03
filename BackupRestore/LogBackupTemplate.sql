/*
 * Script: Transaction Log Backup Template (SQL Server)
 * Description: Template for creating transaction log backups
 * 
 * This script performs transaction log backups, which are essential for:
 *   - Point-in-time recovery
 *   - Minimizing data loss
 *   - Managing transaction log file size
 * 
 * Requirements:
 *   - Database must be in FULL or BULK_LOGGED recovery model
 *   - At least one full backup must exist
 * 
 * Usage:
 *   1. Modify the @DatabaseName variable
 *   2. Modify the @BackupPath variable
 *   3. Schedule to run regularly (every 15-30 minutes recommended)
 * 
 * Note: Log backups truncate the inactive portion of the transaction log
 */

-- Configuration
DECLARE @DatabaseName NVARCHAR(128) = 'YourDatabaseName';  -- CHANGE THIS
DECLARE @BackupPath NVARCHAR(256) = 'C:\Backups\Logs\';    -- CHANGE THIS
DECLARE @UseCompression BIT = 1;                            -- 1 = Yes, 0 = No

-- Check recovery model
DECLARE @RecoveryModel NVARCHAR(60);
SELECT @RecoveryModel = recovery_model_desc 
FROM sys.databases 
WHERE name = @DatabaseName;

IF @RecoveryModel NOT IN ('FULL', 'BULK_LOGGED')
BEGIN
    PRINT 'Error: Database [' + @DatabaseName + '] is in ' + @RecoveryModel + ' recovery model.';
    PRINT 'Transaction log backups require FULL or BULK_LOGGED recovery model.';
    RETURN;
END

-- Build backup file name with timestamp
DECLARE @BackupFileName NVARCHAR(256);
DECLARE @Timestamp NVARCHAR(20);
SET @Timestamp = CONVERT(NVARCHAR(20), GETDATE(), 112) + '_' + 
                 REPLACE(CONVERT(NVARCHAR(20), GETDATE(), 108), ':', '');
SET @BackupFileName = @BackupPath + @DatabaseName + '_Log_' + @Timestamp + '.trn';

-- Build backup command
DECLARE @SQL NVARCHAR(MAX);
SET @SQL = 'BACKUP LOG [' + @DatabaseName + '] TO DISK = ''' + @BackupFileName + '''';
SET @SQL = @SQL + ' WITH INIT, CHECKSUM, STATS = 10';

IF @UseCompression = 1
    SET @SQL = @SQL + ', COMPRESSION';

-- Execute backup
PRINT 'Starting transaction log backup of database: ' + @DatabaseName;
PRINT 'Backup file: ' + @BackupFileName;

BEGIN TRY
    EXEC sp_executesql @SQL;
    PRINT 'Log backup completed successfully at: ' + CONVERT(NVARCHAR(20), GETDATE(), 120);
    
    -- Show log space usage after backup
    DBCC SQLPERF(LOGSPACE);
    
END TRY
BEGIN CATCH
    PRINT 'Error occurred during log backup:';
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
    PRINT 'Error Message: ' + ERROR_MESSAGE();
END CATCH
