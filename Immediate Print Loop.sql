----------------------------------------------------------------------------------
-- Loop Example
-- A short example of how to loop and PRINT messages IMMEDIATELY without any 
-- sort of buffering.
----------------------------------------------------------------------------------

WHILE (1 = 1)
BEGIN
    DECLARE @Results VARCHAR(MAX) = FORMAT(GETDATE(), 'HH:mm:ss') + ': '

    SELECT @Results = @Results + 'SomeTable: ' + CAST(COUNT(1) AS VARCHAR(10)) + '   |  '
    FROM SomeDB.[dbo].[SomeTable] WITH (NOLOCK)

    SELECT @Results = @Results + 'SomeOtherTable: ' + CAST(COUNT(1) AS VARCHAR(10)) + '   |  '
    FROM [SomeDb].dbo.[SomeOtherTable] WITH (NOLOCK)

    RAISERROR(@Results, 0, 1) WITH NOWAIT

    WAITFOR DELAY '00:00:30'
END
