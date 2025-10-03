/*
 * Script: Create Login and User Template (SQL Server)
 * Description: Template for creating SQL Server logins and database users
 * 
 * This script provides a template for:
 *   - Creating SQL Server authentication logins
 *   - Creating database users mapped to logins
 *   - Assigning database roles
 *   - Granting specific permissions
 * 
 * Usage:
 *   1. Modify the variables in the Configuration section
 *   2. Uncomment and modify the permissions section as needed
 *   3. Execute the script
 * 
 * Security Best Practices:
 *   - Use strong passwords
 *   - Follow principle of least privilege
 *   - Use Windows authentication when possible
 *   - Regularly review and audit permissions
 */

-- Configuration
DECLARE @LoginName NVARCHAR(128) = 'AppUser01';           -- CHANGE THIS
DECLARE @Password NVARCHAR(128) = 'StrongP@ssw0rd123!';   -- CHANGE THIS
DECLARE @DatabaseName NVARCHAR(128) = 'YourDatabase';     -- CHANGE THIS
DECLARE @DefaultDatabase NVARCHAR(128) = 'YourDatabase';  -- CHANGE THIS
DECLARE @DatabaseRole NVARCHAR(128) = 'db_datareader';    -- CHANGE THIS (db_owner, db_datareader, db_datawriter, etc.)

-- Check if login already exists
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @LoginName)
BEGIN
    DECLARE @CreateLoginSQL NVARCHAR(MAX);
    SET @CreateLoginSQL = '
    CREATE LOGIN [' + @LoginName + '] 
    WITH PASSWORD = ''' + @Password + ''',
    DEFAULT_DATABASE = [' + @DefaultDatabase + '],
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = ON;';
    
    EXEC sp_executesql @CreateLoginSQL;
    PRINT 'Login [' + @LoginName + '] created successfully.';
END
ELSE
BEGIN
    PRINT 'Login [' + @LoginName + '] already exists.';
END

-- Create database user
DECLARE @CreateUserSQL NVARCHAR(MAX);
SET @CreateUserSQL = 'USE [' + @DatabaseName + ']; ';

-- Check if user exists in database
SET @CreateUserSQL = @CreateUserSQL + '
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @LoginName + ''')
BEGIN
    CREATE USER [' + @LoginName + '] FOR LOGIN [' + @LoginName + '];
    PRINT ''User [' + @LoginName + '] created in database [' + @DatabaseName + '].'';
END
ELSE
BEGIN
    PRINT ''User [' + @LoginName + '] already exists in database [' + @DatabaseName + '].'';
END';

EXEC sp_executesql @CreateUserSQL;

-- Add user to database role
DECLARE @AddRoleSQL NVARCHAR(MAX);
SET @AddRoleSQL = 'USE [' + @DatabaseName + ']; ';
SET @AddRoleSQL = @AddRoleSQL + '
ALTER ROLE [' + @DatabaseRole + '] ADD MEMBER [' + @LoginName + '];
PRINT ''User [' + @LoginName + '] added to role [' + @DatabaseRole + '].'';';

EXEC sp_executesql @AddRoleSQL;

-- Optional: Grant specific object permissions
-- Uncomment and modify as needed
/*
DECLARE @GrantPermSQL NVARCHAR(MAX);
SET @GrantPermSQL = 'USE [' + @DatabaseName + ']; ';

-- Grant SELECT on specific table
SET @GrantPermSQL = @GrantPermSQL + '
GRANT SELECT ON dbo.TableName TO [' + @LoginName + '];';

-- Grant EXECUTE on specific stored procedure
SET @GrantPermSQL = @GrantPermSQL + '
GRANT EXECUTE ON dbo.StoredProcedureName TO [' + @LoginName + '];';

EXEC sp_executesql @GrantPermSQL;
*/

PRINT 'User creation and permission assignment completed.';
