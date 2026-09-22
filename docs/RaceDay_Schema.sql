-- ============================================================
-- RaceDay Database Schema
-- SQL Server (SSMS compatible)
-- This script creates all tables, keys, and constraints,
-- then seeds the database with realistic sample data.
-- ============================================================

-- Create the database (skip if running inside an existing DB)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RaceDayDB')
BEGIN
    CREATE DATABASE RaceDayDB;
END
GO

USE RaceDayDB;
GO

-- ============================================================
-- DROP EXISTING TABLES (in dependency order) for clean re-runs
-- ============================================================
IF OBJECT_ID('dbo.Results', 'U') IS NOT NULL DROP TABLE dbo.Results;
IF OBJECT_ID('dbo.Enrolments', 'U') IS NOT NULL DROP TABLE dbo.Enrolments;
IF OBJECT_ID('dbo.EventCategories', 'U') IS NOT NULL DROP TABLE dbo.EventCategories;
IF OBJECT_ID('dbo.Events', 'U') IS NOT NULL DROP TABLE dbo.Events;
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
GO

-- ============================================================
-- TABLE: Users
-- Stores both Organisers and Participants in a single table.
-- The role column determines access level.
-- ============================================================
CREATE TABLE dbo.Users (
    userId          INT IDENTITY(1,1) PRIMARY KEY,
    email           NVARCHAR(256)   NOT NULL UNIQUE,
    passwordHash    NVARCHAR(MAX)   NOT NULL,
    firstName       NVARCHAR(100)   NOT NULL,
    lastName        NVARCHAR(100)   NOT NULL,
    role            NVARCHAR(20)    NOT NULL DEFAULT 'Participant'
                    CHECK (role IN ('Organiser', 'Participant')),
    createdAt       DATETIME2       NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- TABLE: Events
-- Each event is created by one Organiser.
-- ============================================================
CREATE TABLE dbo.Events (
    eventId         INT IDENTITY(1,1) PRIMARY KEY,
    organiserId     INT             NOT NULL,
    name            NVARCHAR(200)   NOT NULL,
    description     NVARCHAR(MAX)   NULL,
    eventDate       DATETIME2       NOT NULL,
    location        NVARCHAR(200)   NOT NULL,
    status          NVARCHAR(20)    NOT NULL DEFAULT 'Upcoming'
                    CHECK (status IN ('Upcoming', 'Active', 'Completed', 'Cancelled')),
    createdAt       DATETIME2       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (organiserId)
        REFERENCES dbo.Users(userId)
);
GO

-- ============================================================
-- TABLE: Categories
-- Race distance categories like 5K, 10K, Half Marathon, etc.
-- ============================================================
CREATE TABLE dbo.Categories (
    categoryId      INT IDENTITY(1,1) PRIMARY KEY,
    name            NVARCHAR(100)   NOT NULL UNIQUE,
    description     NVARCHAR(500)   NULL,
    distanceKm      DECIMAL(5,2)    NOT NULL
);
GO

-- ============================================================
-- TABLE: EventCategories
-- Junction table linking Events to Categories.
-- An event can offer multiple categories (e.g. 5K and 10K).
-- ============================================================
CREATE TABLE dbo.EventCategories (
    eventCategoryId INT IDENTITY(1,1) PRIMARY KEY,
    eventId         INT             NOT NULL,
    categoryId      INT             NOT NULL,
    maxParticipants INT             NULL,
    CONSTRAINT FK_EC_Event FOREIGN KEY (eventId)
        REFERENCES dbo.Events(eventId) ON DELETE CASCADE,
    CONSTRAINT FK_EC_Category FOREIGN KEY (categoryId)
        REFERENCES dbo.Categories(categoryId),
    CONSTRAINT UQ_Event_Category UNIQUE (eventId, categoryId)
);
GO

-- ============================================================
-- TABLE: Enrolments
-- Records a Participant entering a specific event-category.
-- ============================================================
CREATE TABLE dbo.Enrolments (
    enrolmentId     INT IDENTITY(1,1) PRIMARY KEY,
    participantId   INT             NOT NULL,
    eventCategoryId INT             NOT NULL,
    enrolmentDate   DATETIME2       NOT NULL DEFAULT GETDATE(),
    status          NVARCHAR(20)    NOT NULL DEFAULT 'Confirmed'
                    CHECK (status IN ('Confirmed', 'Cancelled', 'DNS', 'DNF')),
    CONSTRAINT FK_Enrolments_Participant FOREIGN KEY (participantId)
        REFERENCES dbo.Users(userId),
    CONSTRAINT FK_Enrolments_EventCategory FOREIGN KEY (eventCategoryId)
        REFERENCES dbo.EventCategories(eventCategoryId)
);
GO

-- ============================================================
-- TABLE: Results
-- Stores finish time and position for enrolled participants.
-- One result per enrolment.
-- ============================================================
CREATE TABLE dbo.Results (
    resultId        INT IDENTITY(1,1) PRIMARY KEY,
    enrolmentId     INT             NOT NULL UNIQUE,
    finishTime      TIME(7)         NOT NULL,
    position        INT             NOT NULL,
    capturedAt      DATETIME2       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Results_Enrolment FOREIGN KEY (enrolmentId)
        REFERENCES dbo.Enrolments(enrolmentId)
);
GO

-- ============================================================
-- SEED DATA
-- ============================================================

-- 2 Organisers
INSERT INTO dbo.Users (email, passwordHash, firstName, lastName, role)
VALUES
    ('sarah.vanwyk@raceday.co.za', 'hashed_pw_placeholder_01', 'Sarah', 'van Wyk', 'Organiser'),
    ('james.naidoo@raceday.co.za', 'hashed_pw_placeholder_02', 'James', 'Naidoo', 'Organiser');

-- 2 Participants
INSERT INTO dbo.Users (email, passwordHash, firstName, lastName, role)
VALUES
    ('thabo.mokoena@gmail.com', 'hashed_pw_placeholder_03', 'Thabo', 'Mokoena', 'Participant'),
    ('lindi.dlamini@outlook.com', 'hashed_pw_placeholder_04', 'Lindi', 'Dlamini', 'Participant');

-- 4 Categories
INSERT INTO dbo.Categories (name, description, distanceKm)
VALUES
    ('5K Fun Run', 'A beginner-friendly 5 kilometre run suitable for all ages.', 5.00),
    ('10K Road Race', 'A competitive 10 kilometre road race.', 10.00),
    ('Half Marathon', 'A 21.1 kilometre half marathon for intermediate to advanced runners.', 21.10),
    ('Full Marathon', 'The classic 42.2 kilometre marathon distance.', 42.20);

-- 3 Events (created by the two organisers)
INSERT INTO dbo.Events (organiserId, name, description, eventDate, location, status)
VALUES
    (1, 'Joburg City Run 2026', 'An annual road race through the streets of Johannesburg.', '2026-11-15 07:00:00', 'Johannesburg, Gauteng', 'Upcoming'),
    (1, 'Soweto Sunrise Dash', 'A community fun run celebrating Soweto heritage.', '2026-10-05 06:30:00', 'Soweto, Gauteng', 'Upcoming'),
    (2, 'Cape Winelands Ultra', 'A scenic ultra-distance run through the Cape Winelands.', '2027-03-22 05:00:00', 'Stellenbosch, Western Cape', 'Upcoming');

-- EventCategories - assign categories to events
INSERT INTO dbo.EventCategories (eventId, categoryId, maxParticipants)
VALUES
    (1, 1, 500),   -- Joburg City Run: 5K
    (1, 2, 300),   -- Joburg City Run: 10K
    (1, 3, 200),   -- Joburg City Run: Half Marathon
    (2, 1, 1000),  -- Soweto Sunrise Dash: 5K
    (2, 2, 500),   -- Soweto Sunrise Dash: 10K
    (3, 3, 250),   -- Cape Winelands Ultra: Half Marathon
    (3, 4, 150);   -- Cape Winelands Ultra: Full Marathon

-- Enrolments
INSERT INTO dbo.Enrolments (participantId, eventCategoryId, enrolmentDate, status)
VALUES
    (3, 2, '2026-09-01 10:00:00', 'Confirmed'),  -- Thabo in Joburg 10K
    (3, 4, '2026-09-02 14:30:00', 'Confirmed'),  -- Thabo in Soweto 5K
    (4, 1, '2026-09-05 08:15:00', 'Confirmed'),  -- Lindi in Joburg 5K
    (4, 5, '2026-09-06 11:00:00', 'Confirmed'),  -- Lindi in Soweto 10K
    (3, 6, '2026-09-10 09:00:00', 'Confirmed');  -- Thabo in Cape Winelands Half

-- Results (for a completed scenario - Soweto event marked completed for demo)
-- Updating Soweto event to Completed for seeding results
UPDATE dbo.Events SET status = 'Completed' WHERE eventId = 2;

INSERT INTO dbo.Results (enrolmentId, finishTime, position)
VALUES
    (2, '00:28:45', 12),   -- Thabo's Soweto 5K result
    (4, '01:02:30', 5);    -- Lindi's Soweto 10K result

GO

PRINT 'RaceDay database schema created and seeded successfully.';
GO
