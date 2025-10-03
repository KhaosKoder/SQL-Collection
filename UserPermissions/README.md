# User & Permissions Management Scripts

This directory contains SQL scripts for managing database users, logins, and permissions.

## Scripts

### UserPermissionsReport.sql
Comprehensive report of all users and their permissions in the current database.

**Key Features:**
- Lists database users and their server logins
- Shows database role memberships
- Displays object-level permissions
- Shows database-level permissions

**Output Sections:**
1. **Database Users and Roles**: Who has access and their roles
2. **Object-Level Permissions**: Specific table/view/procedure permissions
3. **Database-Level Permissions**: Database-wide permissions

**When to Use:**
- Security audits
- Compliance reviews
- Before/after user changes
- Troubleshooting access issues

### CreateUserTemplate.sql
Template for creating new SQL Server logins and database users.

**Key Features:**
- Creates server login
- Creates database user
- Assigns database roles
- Optional object-level permissions

**Configuration:**
- `@LoginName`: Login name to create
- `@Password`: Login password (use strong passwords!)
- `@DatabaseName`: Database to create user in
- `@DatabaseRole`: Role to assign (db_datareader, db_datawriter, etc.)

**Security Best Practices:**
- Use strong, complex passwords
- Follow principle of least privilege
- Prefer Windows authentication when possible
- Document user purpose and permissions

### ServerRolesReport.sql
Shows server-level roles and their members.

**Key Features:**
- Lists all server role memberships
- Highlights sysadmin members (critical!)
- Shows member counts per role
- Includes role descriptions

**When to Use:**
- Server security audits
- Compliance reviews
- After personnel changes
- Regular security reviews

**Critical Information:**
- Special focus on `sysadmin` role members
- These accounts have complete server control
- Should be limited to absolute minimum

## Security Concepts

### Server Logins vs. Database Users

**Server Login:**
- Server-level authentication
- Can connect to SQL Server instance
- Types: SQL Authentication, Windows Authentication

**Database User:**
- Database-level principal
- Mapped to a server login
- Has permissions within specific database

### Fixed Database Roles

| Role | Permissions |
|------|-------------|
| db_owner | All permissions in the database |
| db_securityadmin | Can modify role membership and permissions |
| db_accessadmin | Can add or remove users |
| db_backupoperator | Can backup the database |
| db_ddladmin | Can run DDL commands (CREATE, ALTER, DROP) |
| db_datawriter | Can INSERT, UPDATE, DELETE data |
| db_datareader | Can SELECT from all tables |
| db_denydatawriter | Cannot INSERT, UPDATE, DELETE |
| db_denydatareader | Cannot SELECT from tables |
| public | Default role for all users |

### Fixed Server Roles

| Role | Permissions |
|------|-------------|
| sysadmin | Complete control of SQL Server |
| serveradmin | Configure server-wide settings |
| securityadmin | Manage logins and permissions |
| processadmin | Manage SQL Server processes |
| setupadmin | Add/remove linked servers |
| bulkadmin | Execute BULK INSERT statements |
| diskadmin | Manage backup devices |
| dbcreator | Create, alter, drop databases |
| public | Default role for all logins |

## Security Best Practices

### 1. Principle of Least Privilege
- Grant minimum permissions needed
- Avoid db_owner unless absolutely necessary
- Use specific object permissions when possible

### 2. Authentication
- **Prefer Windows Authentication** (integrated security)
- Use SQL Authentication only when necessary
- Implement strong password policies

### 3. Account Management
- Disable unused accounts promptly
- Review permissions regularly
- Document account purposes
- Remove access when no longer needed

### 4. Audit and Monitoring
- Regularly review UserPermissionsReport.sql
- Monitor sysadmin role members
- Track permission changes
- Review failed login attempts

### 5. Separation of Duties
- Different accounts for different purposes
- Application accounts vs. administrative accounts
- Read-only accounts for reporting

## Common Permission Scenarios

### Read-Only User
```sql
-- Add to db_datareader role
ALTER ROLE db_datareader ADD MEMBER [UserName];
```

### Read-Write User
```sql
-- Add to both reader and writer roles
ALTER ROLE db_datareader ADD MEMBER [UserName];
ALTER ROLE db_datawriter ADD MEMBER [UserName];
```

### Application User (Specific Objects)
```sql
-- Grant specific permissions
GRANT SELECT, INSERT, UPDATE ON dbo.TableName TO [UserName];
GRANT EXECUTE ON dbo.StoredProcName TO [UserName];
```

### Backup Operator
```sql
-- Add to backup operator role
ALTER ROLE db_backupoperator ADD MEMBER [UserName];
```

## Audit Checklist

### Monthly Security Review
- [ ] Run UserPermissionsReport.sql for each database
- [ ] Run ServerRolesReport.sql
- [ ] Review sysadmin members
- [ ] Verify all accounts are still needed
- [ ] Check for accounts with excessive permissions
- [ ] Document any findings

### After Personnel Changes
- [ ] Remove access for departed staff
- [ ] Review permissions for role changes
- [ ] Update documentation
- [ ] Verify no orphaned accounts

### Compliance Requirements
- [ ] Document all privileged accounts
- [ ] Maintain permission change log
- [ ] Regular audit reports
- [ ] Review against security policy

## Troubleshooting Common Issues

### Orphaned Users
**Problem:** User exists in database but login doesn't exist on server

**Solution:**
```sql
-- Fix orphaned user
ALTER USER [UserName] WITH LOGIN = [LoginName];

-- Or drop and recreate
DROP USER [UserName];
CREATE USER [UserName] FOR LOGIN [LoginName];
```

### Permission Denied
**Diagnosis:**
1. Check database role membership
2. Review object-level permissions
3. Check schema ownership
4. Verify login is not disabled

### Cannot Connect
**Check:**
1. Login exists: `SELECT * FROM sys.server_principals WHERE name = 'LoginName'`
2. Login is enabled: `is_disabled` column
3. Database user exists: `SELECT * FROM sys.database_principals WHERE name = 'UserName'`
4. Network connectivity and firewall rules

## Important Notes

- **Never** share login credentials
- **Always** use strong passwords for SQL Authentication
- **Regularly** review and audit permissions
- **Document** all permission grants with business justification
- **Test** permission changes in development first
- **Back up** before making bulk permission changes
