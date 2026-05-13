USE master;
GO

IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'PrivacyVault')
BEGIN
    ALTER DATABASE PrivacyVault SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PrivacyVault;
END
GO

CREATE DATABASE PrivacyVault;
GO

USE PrivacyVault;
GO


create table users(
    user_id int primary key identity(1,1),
    name nvarchar(100) not null,
    email nvarchar(150) not null unique,
    password_hash nvarchar(255) not null,
    phone nvarchar(20),
    account_status nvarchar(20) 
    constraint chk_user_status  check (account_status in ('active','inactive','deleted')) default 'active',
    created_at datetime default getdate(),
    updated_at datetime,
    last_login datetime
);

create table companies(
    company_id int primary key identity(1,1),
    name nvarchar(150) not null,
    website nvarchar(255),
    category nvarchar(100),
    country nvarchar(100),
    is_verified bit default 0,
    created_at datetime default getdate(),
    updated_at datetime,
    constraint uq_company_name unique (name)
);

create table data_categories (
    category_id int primary key identity(1,1),
    category_name nvarchar(100) not null unique,
    sensitivity_level nvarchar(20) not null
    constraint chk_sensitivity check(sensitivity_level in ('low','medium','high')),
    description nvarchar(255)
);

create table consents (
    consent_id int primary key identity(1,1),
    user_id int not null,
    company_id int not null,
    consent_given_date date not null,
    consent_expiry_date date,
    consent_status nvarchar(20)
    constraint chk_consent_status check(consent_status in ('active','expired','revoked'))
    default 'active',
    notes nvarchar(255),
    created_at datetime default getdate(),
    updated_at datetime,
    constraint uq_user_company unique (user_id, company_id),
    constraint fk_consent_user foreign key (user_id) references users(user_id) on delete cascade,
    constraint fk_consent_company foreign key (company_id) references companies(company_id) on delete cascade,
    constraint chk_dates check(consent_expiry_date is null or consent_expiry_date >= consent_given_date)
);

create table consent_data (
    consent_data_id int primary key identity(1,1),
    consent_id int not null,
    category_id int not null,
    constraint fk_cd_consent foreign key(consent_id) references consents(consent_id) on delete cascade,
    constraint fk_cd_category foreign key(category_id) references data_categories(category_id) on delete cascade,
    constraint uq_consent_category unique(consent_id, category_id)
);

create table deletion_requests(
    request_id int primary key identity(1,1),
    user_id int not null,
    company_id int not null,
    request_date date default getdate(),
    target_data nvarchar(255),
    status nvarchar(20)
    constraint chk_request_status check(status in ('pending','completed','rejected')) default 'pending',
    response_date date,
    notes nvarchar(255),
    constraint uq_request unique (user_id, company_id, request_date),
    constraint fk_req_user foreign key (user_id) references users(user_id),
    constraint fk_req_company foreign key (company_id) references companies(company_id),
    constraint chk_response_date check (response_date is null or response_date >= request_date)
);

create table ratings(
    rating_id int primary key identity(1,1),
    user_id int not null,
    company_id int not null,
    rating int not null
    constraint chk_rating check (rating between 1 and 5),
    review nvarchar(255),
    created_at datetime default getdate(),
    constraint fk_rating_user foreign key (user_id) references users(user_id),
    constraint fk_rating_company foreign key(company_id) references companies(company_id),
    constraint uq_user_company_rating unique(user_id, company_id)
);

create table breach_records (
    breach_id int primary key identity(1,1),
    company_id int not null,
    breach_date date not null,
    breach_type nvarchar(100),
    severity nvarchar(20)
    constraint chk_severity check(severity in('low','medium','high')),
    description nvarchar(255),
    constraint fk_breach_company foreign key(company_id) references companies(company_id)
);

-- Digital Exposure Monitoring (3NF: matches reference breach_records; no duplicate company/date/severity)
create table exposure_scans (
    scan_id int primary key identity(1,1),
    user_id int not null,
    email_checked nvarchar(255) not null,
    phone_checked nvarchar(30),
    usernames_checked nvarchar(500),
    scan_date datetime2(0) not null default sysutcdatetime(),
    risk_score int not null default 0
        constraint chk_exposure_risk check (risk_score >= 0 and risk_score <= 100),
    scan_status nvarchar(20) not null default 'completed'
        constraint chk_exposure_status check (scan_status in ('pending','completed','failed')),
    constraint fk_exposure_user foreign key (user_id) references users(user_id) on delete cascade
);

-- One row per (scan, breach): severity/date/company come from breach_records + companies via breach_id
create table breach_matches (
    match_id int primary key identity(1,1),
    scan_id int not null,
    breach_id int not null,
    data_exposed nvarchar(500) not null default '',
    description nvarchar(1000) not null default '',
    constraint fk_match_scan foreign key (scan_id) references exposure_scans(scan_id) on delete cascade,
    constraint fk_match_breach foreign key (breach_id) references breach_records(breach_id) on delete cascade,
    constraint uq_scan_breach unique (scan_id, breach_id)
);

create table recommendations (
    recommendation_id int primary key identity(1,1),
    scan_id int not null,
    title nvarchar(200) not null,
    description nvarchar(1000) not null,
    priority_level nvarchar(20) not null default 'medium'
        constraint chk_rec_priority check (priority_level in ('low','medium','high')),
    constraint fk_rec_scan foreign key (scan_id) references exposure_scans(scan_id) on delete cascade
);

create table activity_logs(
    log_id int primary key identity(1,1),
    user_id int,
    action_type nvarchar(50)
    constraint chk_action check(action_type in('insert','update','delete')),
    table_name nvarchar(100),
    description nvarchar(255),
    created_at datetime default getdate(),
    constraint fk_log_user foreign key (user_id) references users(user_id)
);

GO

-- ==========================================
-- 2. VIEw
-- ==========================================

-- View 1: Active Consents Detail View
-- This view simplifies the UI queries by joining users, companies, and their active consent categories.
CREATE VIEW vw_UserActiveConsents AS
SELECT 
    c.consent_id,
    u.user_id,
    u.name AS user_name,
    u.email AS user_email,
    comp.name AS company_name,
    c.consent_given_date,
    c.consent_expiry_date,
    dc.category_name,
    dc.sensitivity_level
FROM consents c
JOIN users u ON c.user_id = u.user_id
JOIN companies comp ON c.company_id = comp.company_id
JOIN consent_data cd ON c.consent_id = cd.consent_id
JOIN data_categories dc ON cd.category_id = dc.category_id
WHERE c.consent_status = 'active';
GO

-- View 2: Pending Deletion Requests
-- Used by the Admin panel to quickly see all deletion requests that still need action.
CREATE VIEW vw_PendingDeletionRequests AS
SELECT 
    dr.request_id,
    u.user_id,
    u.name AS user_name,
    u.email AS user_email,
    c.name AS company_name,
    dr.request_date,
    dr.status
FROM deletion_requests dr
JOIN users u ON dr.user_id = u.user_id
JOIN companies c ON dr.company_id = c.company_id
WHERE dr.status = 'pending';
GO

-- View 3: Company Risk Profile (Breaches and Ratings)
-- Used in the User Dashboard to show a summary of a company's reliability.
CREATE VIEW vw_CompanyRiskProfile AS
SELECT 
    c.company_id,
    c.name AS company_name,
    c.is_verified,
    ISNULL(AVG(CAST(r.rating AS DECIMAL(10,2))), 3) AS average_rating,
    COUNT(DISTINCT b.breach_id) AS total_breaches
FROM companies c
LEFT JOIN ratings r ON c.company_id = r.company_id
LEFT JOIN breach_records b ON c.company_id = b.company_id
GROUP BY c.company_id, c.name, c.is_verified;
GO

-- ==========================================
-- 3. STORED PROCEDURES (With Transactions)
-- ==========================================

-- SP 1: Add User securely
CREATE PROCEDURE sp_RegisterUser
    @name nvarchar(100),
    @email nvarchar(150),
    @password_hash nvarchar(255),
    @phone nvarchar(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF EXISTS (SELECT 1 FROM users WHERE email = @email)
        BEGIN
            RAISERROR('Email already exists', 16, 1);
        END

        INSERT INTO users (name, email, password_hash, phone)
        VALUES (@name, @email, @password_hash, @phone);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP 2: Grant Consent (Handles Consent and Consent Data)
-- This procedure safely inserts into both 'consents' and 'consent_data' using a transaction.
CREATE PROCEDURE sp_GrantConsent
    @user_id int,
    @company_id int,
    @consent_expiry_date date = NULL,
    @category_id int,
    @notes nvarchar(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @consent_id int;
        
        -- Check if a consent already exists between user and company
        SELECT @consent_id = consent_id FROM consents 
        WHERE user_id = @user_id AND company_id = @company_id;

        IF @consent_id IS NULL
        BEGIN
            -- Create new consent record
            INSERT INTO consents (user_id, company_id, consent_given_date, consent_expiry_date, notes)
            VALUES (@user_id, @company_id, GETDATE(), @consent_expiry_date, @notes);
            
            SET @consent_id = SCOPE_IDENTITY();
        END
        
        -- Add the category data
        IF NOT EXISTS (SELECT 1 FROM consent_data WHERE consent_id = @consent_id AND category_id = @category_id)
        BEGIN
            INSERT INTO consent_data (consent_id, category_id)
            VALUES (@consent_id, @category_id);
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP 3: Process Deletion Request
-- Updates the status of a request and automatically revokes consents if approved.
CREATE PROCEDURE sp_ProcessDeletionRequest
    @request_id int,
    @new_status nvarchar(20),
    @notes nvarchar(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        UPDATE deletion_requests
        SET status = @new_status, 
            response_date = GETDATE(), 
            notes = @notes
        WHERE request_id = @request_id;
        
        -- If approved, we auto-revoke consents for this company
        IF @new_status = 'completed'
        BEGIN
            DECLARE @user_id int, @company_id int;
            SELECT @user_id = user_id, @company_id = company_id 
            FROM deletion_requests WHERE request_id = @request_id;

            UPDATE consents
            SET consent_status = 'revoked', updated_at = GETDATE()
            WHERE user_id = @user_id AND company_id = @company_id AND consent_status = 'active';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ==========================================
-- 4. TRIGGERS
-- ==========================================

-- Trigger 1: Log when a user is updated or deleted
CREATE TRIGGER trg_AuditUserChanges
ON users
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Log Updates
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO activity_logs (user_id, action_type, table_name, description)
        SELECT i.user_id, 'update', 'users', 'User profile updated. Status: ' + i.account_status
        FROM inserted i;
    END

    -- Log Deletions
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO activity_logs (user_id, action_type, table_name, description)
        SELECT d.user_id, 'delete', 'users', 'User account permanently deleted.'
        FROM deleted d;
    END
END;
GO

-- Trigger 2: Log new deletion requests
CREATE TRIGGER trg_AuditDeletionRequests
ON deletion_requests
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO activity_logs (user_id, action_type, table_name, description)
    SELECT i.user_id, 'insert', 'deletion_requests', 'Submitted data deletion request for Company ID: ' + CAST(i.company_id AS nvarchar)
    FROM inserted i;
END;
GO

-- Trigger 3: Automatically update consent timestamps
CREATE TRIGGER trg_UpdateConsentTimestamp
ON consents
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(updated_at)
    BEGIN
        UPDATE c
        SET updated_at = GETDATE()
        FROM consents c
        INNER JOIN inserted i ON c.consent_id = i.consent_id;
    END
END;
GO

-- ==========================================
-- 5. INITIAL DATA INSERTION
-- ==========================================

-- Users
insert into users(name,email,password_hash,phone) values
('Ali Khan', 'ali@gmail.com','hash1','03001234567'),
('Sara Ahmed', 'sara@gmail.com', 'hash2', '03111234567'),
('Usman Tariq', 'usman@gmail.com', 'hash3', '03221234567');

-- Companies
insert into companies(name,website,category,country) values
('Facebook', 'facebook.com', 'social media', 'USA'),
('Google', 'google.com', 'technology', 'USA'),
('Daraz', 'daraz.pk', 'e-commerce', 'Pakistan'),
('LinkedIn', 'linkedin.com', 'professional', 'USA');

-- Data Categories
insert into data_categories (category_name, sensitivity_level) values
('email', 'low'),
('phone', 'medium'),
('address', 'high'),
('location', 'high'),
('payment info', 'high');

-- Consents
insert into consents (user_id, company_id, consent_given_date, consent_expiry_date) values
(1, 1, '2023-01-01', '2025-01-01'),
(1, 2, '2023-05-10', null),
(2, 3, '2024-02-15', '2026-02-15'),
(3, 1, '2022-07-20', '2024-07-20');

-- Consent Data
insert into consent_data (consent_id, category_id) values
(1, 1), (1, 2), (2, 1), (3, 3), (4, 1), (4, 4); 

-- Deletion Requests
insert into deletion_requests (user_id,company_id,status,request_date) values
(1, 1, 'pending', '2025-01-01'),
(2, 3, 'completed', '2025-02-10');

-- Ratings
insert into ratings (user_id, company_id, rating, review) values
(1, 1, 2, 'slow response'),
(2, 3, 4, 'good service'),
(3, 1, 3, 'average privacy');

-- Breach Records
insert into breach_records (company_id, breach_date, severity, description) values
(1, '2022-03-10', 'high', 'data leak'),
(2, '2023-06-15', 'medium', 'partial exposure');

insert into activity_logs (user_id, action_type, table_name, description) values
(1, 'insert', 'consents', 'user added consent'),
(2, 'update', 'deletion_requests', 'status updated');

-- Sample exposure scan (optional demo for UI; matches reference breach_id only — 3NF)
insert into exposure_scans (user_id, email_checked, phone_checked, usernames_checked, risk_score, scan_status)
values (1, N'demo.user@facebook.com', null, null, 55, 'completed');

insert into breach_matches (scan_id, breach_id, data_exposed, description)
select top 1 es.scan_id, 1,
    N'email addresses, passwords or credentials',
    N'Sample row: scan correlated to breach_records.breach_id 1 (known-source monitoring only).'
from exposure_scans es
where es.user_id = 1
order by es.scan_id desc;

insert into recommendations (scan_id, title, description, priority_level)
select top 1 es.scan_id,
    N'Enable two-factor authentication (2FA)',
    N'Turn on 2FA on accounts tied to identifiers you checked.',
    'medium'
from exposure_scans es
where es.user_id = 1
order by es.scan_id desc;

insert into recommendations (scan_id, title, description, priority_level)
select top 1 es.scan_id,
    N'Change passwords for affected accounts',
    N'Use unique passwords per service when a breach match appears in your scan history.',
    'high'
from exposure_scans es
where es.user_id = 1
order by es.scan_id desc;
GO
