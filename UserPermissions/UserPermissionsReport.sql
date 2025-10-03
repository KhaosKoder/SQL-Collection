/*
 * Script: User Permissions Report (SQL Server)
 * Description: Shows all users and their permissions in the current database
 * 
 * This script provides a comprehensive view of database users, their roles,
 * and specific object-level permissions.
 * 
 * Output includes:
 *   - Database users and their associated server logins
 *   - Database roles assigned to each user
 *   - Object-level permissions (tables, views, procedures, etc.)
 * 
 * Usage:
 *   - Run to audit database permissions
 *   - Use for compliance and security reviews
 *   - Identify overly-permissive accounts
 * 
 * Note: Run this in each database you want to audit
 */

-- Part 1: Database Users and Roles
SELECT 
    dp.name AS user_name,
    dp.type_desc AS user_type,
    sp.name AS login_name,
    dp.create_date,
    dp.modify_date,
    STRING_AGG(drole.name, ', ') AS database_roles
FROM 
    sys.database_principals dp
    LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
    LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
    LEFT JOIN sys.database_principals drole ON drm.role_principal_id = drole.principal_id
WHERE 
    dp.type IN ('S', 'U', 'G')  -- SQL user, Windows user, Windows group
    AND dp.name NOT IN ('guest', 'INFORMATION_SCHEMA', 'sys')
GROUP BY
    dp.name, dp.type_desc, sp.name, dp.create_date, dp.modify_date
ORDER BY 
    dp.name;

-- Part 2: Object-Level Permissions
SELECT 
    dp.name AS user_name,
    dp.type_desc AS user_type,
    o.name AS object_name,
    o.type_desc AS object_type,
    p.permission_name,
    p.state_desc AS permission_state
FROM 
    sys.database_permissions p
    INNER JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
    LEFT JOIN sys.objects o ON p.major_id = o.object_id
WHERE 
    dp.type IN ('S', 'U', 'G')
    AND dp.name NOT IN ('guest', 'INFORMATION_SCHEMA', 'sys', 'public')
ORDER BY 
    dp.name,
    o.name,
    p.permission_name;

-- Part 3: Database-Level Permissions
SELECT 
    dp.name AS user_name,
    p.permission_name,
    p.state_desc AS permission_state
FROM 
    sys.database_permissions p
    INNER JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE 
    p.class = 0  -- Database-level permissions
    AND dp.type IN ('S', 'U', 'G')
    AND dp.name NOT IN ('guest', 'INFORMATION_SCHEMA', 'sys', 'public')
ORDER BY 
    dp.name,
    p.permission_name;
