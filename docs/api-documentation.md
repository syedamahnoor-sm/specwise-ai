# SpecWise API Documentation

## Workflow 1 — Project Intake API

**Status:** Implemented and locally tested

This API creates a new software project in the SpecWise PostgreSQL database.

### Endpoint

| Property | Value |
|---|---|
| Method | POST |
| Production path | `/webhook/specwise/projects` |
| Test path | `/webhook-test/specwise/projects` |
| Content type | `application/json` |
| Authentication | Header API Key |

**Local test URL:**

`http://localhost:5678/webhook-test/specwise/projects`

The production webhook requires the n8n workflow to be activated or published.

### Authentication

All requests require an HTTP header:

`x-api-key: YOUR_API_KEY`

The actual key must be stored securely and must never be committed to GitHub or exposed in frontend JavaScript.

### Request Body

```json
{
  "title": "Smart Attendance System",
  "initial_idea": "A university attendance management system."
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `title` | String | Yes | Non-empty after trimming; maximum 255 characters |
| `initial_idea` | String | Yes | Non-empty after trimming; maximum 10,000 characters |

Leading and trailing whitespace is removed before saving.

### Success Response — HTTP 201

```json
{
  "success": true,
  "message": "Project created successfully",
  "project": {
    "id": "aaf6fbc0-5601-4779-a3bf-58e79d4eef76",
    "title": "Smart Attendance System",
    "initial_idea": "A university attendance management system.",
    "status": "draft",
    "created_at": "2026-10-23T10:00:00.000Z"
  }
}
```

The UUID and timestamp above are illustrative.

### Validation Error — HTTP 400

```json
{
  "success": false,
  "message": "Invalid project information.",
  "errors": [
    "Project title is required and must be a string."
  ]
}
```

### Authentication Error — HTTP 403

A request without the required API key is rejected by n8n before reaching the workflow's validation logic.

### Database Error — HTTP 503

```json
{
  "success": false,
  "message": "Database service is temporarily unavailable. Please try again later."
}
```

### Tested Scenarios

| Test Case | Expected Status | Result |
|---|---|---|
| Valid authenticated project creation | 201 | Passed |
| Empty or whitespace-only title | 400 | Passed |
| Numeric title | 400 | Passed |
| Title longer than 255 characters | 400 | Passed |
| Missing initial idea | 400 | Passed |
| Missing API key | 403 | Passed |
| PostgreSQL service unavailable | 503 | Passed |

### Database Operation

The workflow uses a parameterized PostgreSQL query to insert a project into the `projects` table. Parameterization prevents request values from being directly concatenated into the SQL statement.

### Current Limitations

- Only project creation is implemented.
- End-user authentication and project-level authorization are not yet implemented.
- API-key authentication is intended for trusted backend-to-backend requests.
- Rate limiting and duplicate-request protection are not yet implemented.
- The API is currently deployed in a local Docker development environment.

### Workflow Import

Import `workflows/01-project-intake-api.json` into n8n and configure the Header Auth and PostgreSQL credentials for the target environment. Ensure the PostgreSQL schema has been initialized before testing.