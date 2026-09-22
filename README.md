# RaceDay

A full-stack web-based event management system designed for the South African road running, walking, and cycling community. RaceDay allows Event Organisers to create and manage events, categories, and participant results, while Participants can browse upcoming events, enter races, track their performance history, and prepare for race day.

## System Roles

| Role | Capabilities |
|---|---|
| **Organiser** | Create, edit, and delete events. Manage event categories. Capture participant results. View all event enrolments. |
| **Participant** | Create an account. Browse events. Enter an event by selecting a category. View their own enrolments. Track personal results and performance history. |

Role-based access is enforced at the API level and reflected consistently in the MVC interface.

## Repository Structure

```
raceday/
├── .github/
│   └── workflows/
│       └── docs-check.yml          # CI workflow to validate /docs contents
├── docs/
│   ├── RaceDay_ERD.png             # Entity Relationship Diagram
│   ├── API_Endpoint_Plan.md        # Full API endpoint specification
│   └── RaceDay_Schema.sql          # SQL Server database script
├── README.md                       # This file
```

## Setup Instructions

### Prerequisites
- SQL Server 2019+ or SQL Server Express
- SQL Server Management Studio (SSMS)

### Database Setup
1. Open SSMS and connect to your SQL Server instance.
2. Open `docs/RaceDay_Schema.sql`.
3. Execute the script. It will create the `RaceDayDB` database, all six tables, constraints, and seed data.
4. Verify: expand the `RaceDayDB` database in Object Explorer and confirm all tables are present (Users, Events, Categories, EventCategories, Enrolments, Results).

### Verifying Seed Data
After running the script, you can run these quick checks:
```sql
SELECT * FROM dbo.Users;          -- Should return 4 rows (2 Organisers, 2 Participants)
SELECT * FROM dbo.Events;         -- Should return 3 events
SELECT * FROM dbo.Categories;     -- Should return 4 categories
SELECT * FROM dbo.Enrolments;     -- Should return 5 enrolments
SELECT * FROM dbo.Results;        -- Should return 2 results
```

## Planning Documents

- **ERD:** `docs/RaceDay_ERD.png` — Six entities with primary keys, foreign keys, and cardinality.
- **API Endpoint Plan:** `docs/API_Endpoint_Plan.md` — Every endpoint the system will expose, with HTTP methods, routes, roles, request bodies, and expected responses.
- **SQL Script:** `docs/RaceDay_Schema.sql` — Creates the full schema and seeds the database. Runs cleanly on a fresh SQL Server instance.

## CI/CD

A GitHub Actions workflow (`.github/workflows/docs-check.yml`) validates that the `/docs` folder exists and contains the required planning files on every push.

**CI Screenshot:**

![CI Green Build](ci-screenshot.png)

## Video Presentation

**YouTube Link:** [Insert unlisted YouTube link here]

The video walks through the ERD decisions, endpoint plan choices, and demonstrates the SQL script running live in SSMS.
