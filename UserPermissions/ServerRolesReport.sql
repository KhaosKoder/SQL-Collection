/*
 * Script: Server Roles and Members (SQL Server)
 * Description: Shows server-level roles and their members
 * 
 * This script lists all server roles and the logins that are members of each role.
 * Server roles provide server-wide permissions.
 * 
 * Fixed Server Roles:
 *   - sysadmin: Complete control of the server
 *   - serveradmin: Can configure server-wide settings
 *   - securityadmin: Can manage logins and permissions
 *   - processadmin: Can manage SQL Server processes
 *   - setupadmin: Can add/remove linked servers
 *   - bulkadmin: Can run BULK INSERT
 *   - diskadmin: Can manage backup devices
 *   - dbcreator: Can create, alter, drop databases
 *   - public: Default role for all logins
 * 
 * Usage:
 *   - Run to audit server-level permissions
 *   - Identify accounts with elevated privileges
 *   - Review for security compliance
 * 
 * Security Note: Members of sysadmin have complete control - audit carefully!
 */

-- Server Roles and Their Members
SELECT 
    srole.name AS server_role,
    sp.name AS member_name,
    sp.type_desc AS member_type,
    sp.create_date,
    sp.modify_date,
    sp.is_disabled,
    CASE 
        WHEN srole.name = 'sysadmin' THEN 'Full server control - AUDIT CAREFULLY'
        WHEN srole.name = 'securityadmin' THEN 'Can manage logins and permissions'
        WHEN srole.name = 'serveradmin' THEN 'Can configure server settings'
        WHEN srole.name = 'processadmin' THEN 'Can manage processes'
        WHEN srole.name = 'dbcreator' THEN 'Can create/alter/drop databases'
        WHEN srole.name = 'diskadmin' THEN 'Can manage backup devices'
        WHEN srole.name = 'bulkadmin' THEN 'Can execute BULK INSERT'
        WHEN srole.name = 'setupadmin' THEN 'Can manage linked servers'
        ELSE 'Standard permissions'
    END AS role_description
FROM 
    sys.server_role_members srm
    INNER JOIN sys.server_principals srole ON srm.role_principal_id = srole.principal_id
    INNER JOIN sys.server_principals sp ON srm.member_principal_id = sp.principal_id
WHERE
    sp.type IN ('S', 'U', 'G')  -- SQL Login, Windows Login, Windows Group
ORDER BY 
    srole.name,
    sp.name;

-- Summary: Count of members per role
SELECT 
    srole.name AS server_role,
    COUNT(sp.principal_id) AS member_count
FROM 
    sys.server_role_members srm
    INNER JOIN sys.server_principals srole ON srm.role_principal_id = srole.principal_id
    INNER JOIN sys.server_principals sp ON srm.member_principal_id = sp.principal_id
WHERE
    sp.type IN ('S', 'U', 'G')
GROUP BY 
    srole.name
ORDER BY 
    member_count DESC;

-- Logins with sysadmin privileges (CRITICAL - Review carefully!)
SELECT 
    sp.name AS sysadmin_member,
    sp.type_desc AS member_type,
    sp.create_date,
    sp.modify_date,
    sp.is_disabled,
    sp.default_database_name
FROM 
    sys.server_role_members srm
    INNER JOIN sys.server_principals srole ON srm.role_principal_id = srole.principal_id
    INNER JOIN sys.server_principals sp ON srm.member_principal_id = sp.principal_id
WHERE
    srole.name = 'sysadmin'
    AND sp.type IN ('S', 'U', 'G')
ORDER BY 
    sp.name;
