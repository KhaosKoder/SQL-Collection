/*
 * Script: Full Database Backup Template (SQL Server)
 * Description: Template for creating full database backups
 * 
 * This script provides a template for performing full database backups with
 * various options including compression, verification, and checksums.
 * 
 * Usage:
 *   1. Modify the @DatabaseName variable
 *   2. Modify the @BackupPath variable to your backup location
 *   3. Adjust options as needed
 *   4. Execute the script
 * 
 * Options:
 *   - COMPRESSION: Reduces backup size (Enterprise Edition or SQL Server 2008 R2 SP1+)
 *   - CHECKSUM: Validates backup integrity
 *   - INIT: Overwrites existing backup file
 *   - FORMAT: Formats the media (overwrites all backups)
 *   - STATS: Shows progress percentage
 * 
 * Warning: Ensure sufficient disk space before running
 */

-- Configuration
DECLARE @DatabaseName NVARCHAR(128) = 'YourDatabaseName';  -- CHANGE THIS
DECLARE @BackupPath NVARCHAR(256) = 'C:\Backups\';         -- CHANGE THIS
DECLARE @UseCompression BIT = 1;                            -- 1 = Yes, 0 = No
DECLARE @Verify BIT = 1;                                    -- 1 = Yes, 0 = No

-- Build backup file name with timestamp
DECLARE @BackupFileName NVARCHAR(256);
DECLARE @Timestamp NVARCHAR(20);
SET @Timestamp = CONVERT(NVARCHAR(20), GETDATE(), 112) + '_' + 
                 REPLACE(CONVERT(NVARCHAR(20), GETDATE(), 108), ':', '');
SET @BackupFileName = @BackupPath + @DatabaseName + '_Full_' + @Timestamp + '.bak';

-- Build backup command
DECLARE @SQL NVARCHAR(MAX);
SET @SQL = 'BACKUP DATABASE [' + @DatabaseName + '] TO DISK = ''' + @BackupFileName + '''';
SET @SQL = @SQL + ' WITH INIT, CHECKSUM, STATS = 10';

IF @UseCompression = 1
    SET @SQL = @SQL + ', COMPRESSION';

-- Execute backup
PRINT 'Starting full backup of database: ' + @DatabaseName;
PRINT 'Backup file: ' + @BackupFileName;
PRINT 'Command: ' + @SQL;

BEGIN TRY
    EXEC sp_executesql @SQL;
    PRINT 'Backup completed successfully at: ' + CONVERT(NVARCHAR(20), GETDATE(), 120);
    
    -- Verify backup if requested
    IF @Verify = 1
    BEGIN
        PRINT 'Verifying backup...';
        RESTORE VERIFYONLY FROM DISK = @BackupFileName WITH CHECKSUM;
        PRINT 'Backup verification completed successfully.';
    END
    
    -- Show backup file size
    DECLARE @BackupSize TABLE (BackupName NVARCHAR(256), BackupSizeMB DECIMAL(10, 2));
    INSERT INTO @BackupSize
    EXEC xp_cmdshell 'forfiles /P "' + @BackupPath + '" /M "' + @DatabaseName + '_Full_' + @Timestamp + '.bak" /C "cmd /c echo @file @fsize"';
    
END TRY
BEGIN CATCH
    PRINT 'Error occurred during backup:';
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
    PRINT 'Error Message: ' + ERROR_MESSAGE();
END CATCH
