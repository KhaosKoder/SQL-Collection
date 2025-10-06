USE <Your databasename here>
go

-- =============================================
-- Script: Identify Uncompressed Tables & Indexes
-- Scope: Current database only
-- Purpose: Generate PAGE compression commands
-- =============================================

SET NOCOUNT ON;

BEGIN TRY
    -- Parameters
    DECLARE @CompressionType NVARCHAR(20) = 'PAGE'; -- Compression type to apply
    DECLARE @MaxDOP INT = 8;                         -- Max degree of parallelism

    -- Table variable to hold results
    DECLARE @Results TABLE (
        DatabaseName SYSNAME,
        SchemaName NVARCHAR(128),
        TableName NVARCHAR(256),
        IndexName NVARCHAR(256),
        IndexType NVARCHAR(60),
        CompressionType NVARCHAR(60),
        Command NVARCHAR(MAX)
    );

    -- Insert results from current database
    INSERT INTO @Results
    SELECT
        DB_NAME() AS DatabaseName,
        s.name AS SchemaName,
        t.name AS TableName,
        i.name AS IndexName,
        CASE WHEN i.type = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END AS IndexType,
        p.data_compression_desc AS CompressionType,
        'ALTER INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + '] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE, MAXDOP = ' + CONVERT(VARCHAR(3), @MaxDOP) + ');' AS Command
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.indexes i ON t.object_id = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    WHERE p.data_compression = 0
    GROUP BY s.name, t.name, i.name, i.type, p.data_compression_desc;

    -- =============================================
    -- Example Queries
    -- =============================================

    -- Full sorted output
    SELECT *
    FROM @Results
    ORDER BY SchemaName, TableName, IndexType, IndexName;

    -- Only clustered indexes
    SELECT *
    FROM @Results
    WHERE IndexType = 'CLUSTERED'
    ORDER BY SchemaName, TableName;

    -- Count of uncompressed indexes
    SELECT COUNT(*) AS UncompressedIndexCount
    FROM @Results;

    -- Tables with more than one uncompressed index
    SELECT SchemaName, TableName, COUNT(*) AS IndexCount
    FROM @Results
    GROUP BY SchemaName, TableName
    HAVING COUNT(*) > 1
    ORDER BY SchemaName, TableName;

END TRY
BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1) WITH NOWAIT;
END CATCH;
