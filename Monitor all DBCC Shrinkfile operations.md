-------------------------------------------------------------------------------------------
--
-- Continuously checks the progress of all shrinkfile operations running on the server.
--
--------------------------------------------------------------------------------------------


SET NOCOUNT ON;
DECLARE @done BIT = 0;

WHILE @done = 0
BEGIN
    DECLARE @now NVARCHAR(30) = CONVERT(NVARCHAR, GETDATE(), 120);

    ;WITH ShrinkProgress AS (
        SELECT
            r.session_id,
            r.command,
            r.status,
            r.percent_complete,
            r.start_time,
            r.database_id,
            DB_NAME(r.database_id) AS database_name
        FROM sys.dm_exec_requests r
        WHERE r.command = 'DbccFileShrink'
    )
    SELECT @done = CASE 
                      WHEN COUNT(*) = 0 THEN 1
                      WHEN MIN(percent_complete) = 100 THEN 1
                      ELSE 0 
                   END
    FROM ShrinkProgress;

    -- Output progress of each shrink operation
    DECLARE @session_id INT, @db_name NVARCHAR(128), @pct NVARCHAR(10), @start_time NVARCHAR(30), @status NVARCHAR(60);
    DECLARE shrink_cursor CURSOR FOR
        SELECT 
            session_id,
            database_name,
            CAST(percent_complete AS NVARCHAR(10)),
            CONVERT(NVARCHAR(30), start_time, 120),
            status
        FROM (
            SELECT
                r.session_id,
                r.command,
                r.status,
                r.percent_complete,
                r.start_time,
                r.database_id,
                DB_NAME(r.database_id) AS database_name
            FROM sys.dm_exec_requests r
            WHERE r.command = 'DbccFileShrink'
        ) AS ShrinkProgress;

    OPEN shrink_cursor;
    FETCH NEXT FROM shrink_cursor INTO @session_id, @db_name, @pct, @start_time, @status;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        RAISERROR('Shrink progress at %s | SID: %d | DB: %s | %s%% | Started: %s | Status: %s',
                  0, 1, @now, @session_id, @db_name, @pct, @start_time, @status) WITH NOWAIT;

        FETCH NEXT FROM shrink_cursor INTO @session_id, @db_name, @pct, @start_time, @status;
    END

    CLOSE shrink_cursor;
    DEALLOCATE shrink_cursor;

    -- Wait 1 minute if not done
    IF @done = 0
        WAITFOR DELAY '00:01:00';
END

RAISERROR('All DBCC SHRINKFILE operations completed.', 0, 1) WITH NOWAIT;
