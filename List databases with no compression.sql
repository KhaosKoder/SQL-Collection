-- ==========================================================
-- List user databases with compression stats
-- Specifically tells you which db's have NO compression.
-- Also tells you how many items are compressed out of the
-- total items in the db. 
-- ==========================================================

DECLARE @msg NVARCHAR(MAX);
DECLARE @dbName SYSNAME;
DECLARE @sql NVARCHAR(MAX);
DECLARE @hasCompression BIT;
DECLARE @NoCompressionDBs TABLE (DatabaseName SYSNAME);
DECLARE @CompressionStats TABLE (
    DatabaseName SYSNAME,
    TablesCompressed INT,
    TablesTotal INT,
    ClusteredCompressed INT,
    ClusteredTotal INT,
    NonClusteredCompressed INT,
    NonClusteredTotal INT
);

SET NOCOUNT ON;

BEGIN TRY
    DECLARE db_cursor CURSOR FOR
    SELECT name
    FROM sys.databases
    WHERE database_id > 4
      AND state_desc = 'ONLINE';

    OPEN db_cursor;
    FETCH NEXT FROM db_cursor INTO @dbName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @msg = FORMATMESSAGE('Checking database: %s', @dbName);
        RAISERROR(@msg, 0, 1) WITH NOWAIT;

        SET @hasCompression = 0;

        SET @sql = '
            USE [' + @dbName + '];

            DECLARE @tablesTotal INT = (
                SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0
            );

            DECLARE @tablesCompressed INT = (
                SELECT COUNT(DISTINCT t.object_id)
                FROM sys.tables t
                JOIN sys.partitions p ON t.object_id = p.object_id
                WHERE p.data_compression IN (1, 2)
            );

            DECLARE @clusteredTotal INT = (
                SELECT COUNT(*) FROM sys.indexes WHERE type = 1 AND object_id IN (SELECT object_id FROM sys.tables WHERE is_ms_shipped = 0)
            );

            DECLARE @clusteredCompressed INT = (
                SELECT COUNT(DISTINCT i.object_id)
                FROM sys.indexes i
                JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
                WHERE i.type = 1 AND p.data_compression IN (1, 2)
            );

            DECLARE @nonClusteredTotal INT = (
                SELECT COUNT(*) FROM sys.indexes WHERE type = 2 AND object_id IN (SELECT object_id FROM sys.tables WHERE is_ms_shipped = 0)
            );

            DECLARE @nonClusteredCompressed INT = (
                SELECT COUNT(DISTINCT i.object_id)
                FROM sys.indexes i
                JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
                WHERE i.type = 2 AND p.data_compression IN (1, 2)
            );

            DECLARE @hasCompression BIT = CASE 
                WHEN @tablesCompressed > 0 OR @clusteredCompressed > 0 OR @nonClusteredCompressed > 0 THEN 1 
                ELSE 0 
            END;

            SELECT 
                @hasCompression AS hasCompression,
                @tablesCompressed AS TablesCompressed,
                @tablesTotal AS TablesTotal,
                @clusteredCompressed AS ClusteredCompressed,
                @clusteredTotal AS ClusteredTotal,
                @nonClusteredCompressed AS NonClusteredCompressed,
                @nonClusteredTotal AS NonClusteredTotal;';

        DECLARE @result TABLE (
            hasCompression BIT,
            TablesCompressed INT,
            TablesTotal INT,
            ClusteredCompressed INT,
            ClusteredTotal INT,
            NonClusteredCompressed INT,
            NonClusteredTotal INT
        );

        INSERT INTO @result
        EXEC sp_executesql @sql;

        SELECT TOP 1
            @hasCompression = hasCompression
        FROM @result;

        IF @hasCompression = 0
        BEGIN
            INSERT INTO @NoCompressionDBs (DatabaseName)
            VALUES (@dbName);
        END
        ELSE
        BEGIN
            INSERT INTO @CompressionStats
            SELECT @dbName, TablesCompressed, TablesTotal, ClusteredCompressed, ClusteredTotal, NonClusteredCompressed, NonClusteredTotal
            FROM @result;
        END

        FETCH NEXT FROM db_cursor INTO @dbName;
        WAITFOR DELAY '00:00:01';
    END

    CLOSE db_cursor;
    DEALLOCATE db_cursor;

    -- Output
    SELECT 'No compression on : ', DatabaseName FROM @NoCompressionDBs;

    SELECT 
        DatabaseName,
        'HasCompression: 1  Tables: ' + CAST(TablesCompressed AS VARCHAR) + '/' + CAST(TablesTotal AS VARCHAR) +
        '  Clustered Indexes: ' + CAST(ClusteredCompressed AS VARCHAR) + '/' + CAST(ClusteredTotal AS VARCHAR) +
        '  NonClustered Indexes: ' + CAST(NonClusteredCompressed AS VARCHAR) + '/' + CAST(NonClusteredTotal AS VARCHAR)
        AS CompressionSummary
    FROM @CompressionStats;

END TRY
BEGIN CATCH
    SET @msg = FORMATMESSAGE('Error %d: %s', ERROR_NUMBER(), ERROR_MESSAGE());
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END CATCH;
