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

## Workflow 2 — AI Requirements Interviewer

### Endpoint

`POST /webhook/specwise/projects/interview`

Generates clarification questions for an existing software project using Google Gemini Flash-Lite. Questions are validated and stored in PostgreSQL.

If pending questions already exist, the API retrieves them without calling Gemini again.

### Authentication

Header-based API key authentication is required.

| Header | Value |
|---|---|
| `x-api-key` | Configured API key |
| `Content-Type` | `application/json` |

### Request Body

```json
{
  "project_id": "0fe31450-7fc1-4070-a136-d38180b1a205"
}
```

**Validation:** `project_id` must be a valid UUID referencing an existing project.

### Success Response — 201 Created

Returned when the AI generates and saves new clarification questions.

```json
{
  "success": true,
  "message": "Clarification questions generated successfully.",
  "project_id": "0fe31450-7fc1-4070-a136-d38180b1a205",
  "question_count": 1,
  "questions": [
    {
      "id": "cdb3391e-80f6-4325-a9d1-2cb5f7d4ad83",
      "question": "Are there any specific security or data privacy regulations that the system must comply with?",
      "category": "security",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```

The example shows one question for brevity. A successful new interview normally generates 5–7 questions.

### Existing Questions Response — 200 OK

Returned when the project already has pending clarification questions.

```json
{
  "success": true,
  "message": "Existing clarification questions retrieved successfully.",
  "project_id": "0fe31450-7fc1-4070-a136-d38180b1a205",
  "question_count": 5,
  "questions": []
}
```

The `questions` array above is abbreviated; the actual response contains the saved question objects.

### Error Responses

| HTTP status | Meaning |
|---|---|
| `400` | Invalid or missing project ID |
| `403` | Missing or invalid API key |
| `404` | Project not found |
| `503` | Database operation or Gemini service unavailable |

Example Gemini failure response:

```json
{
  "success": false,
  "error": "AI_SERVICE_UNAVAILABLE",
  "message": "Unable to generate clarification questions right now. Please try again later.",
  "project_id": "5fe84315-94f6-424f-b67b-50136f02267f"
}
```

### Question Metadata

**Categories:** `functional`, `non_functional`, `security`, `usability`, `performance`, `stakeholder`, `constraint`.

**Priorities:** `high`, `medium`, `low`.

**Initial status:** `pending`.

### Workflow Processing

1. Authenticate the request and validate the project ID.
2. Retrieve the project from PostgreSQL.
3. Check whether pending clarification questions already exist.
4. Return existing questions if found.
5. Otherwise, ask Gemini Flash-Lite to generate 5–7 questions.
6. Validate the AI-generated JSON structure.
7. Save valid questions to PostgreSQL.
8. Return the generated questions or a structured error response.

### Implementation Notes

- The workflow uses parameterized SQL queries.
- Gemini credentials and PostgreSQL credentials are configured in n8n.
- Duplicate prevention has been verified for sequential requests; concurrent requests require additional safeguards.
- Malformed AI output handling is not yet mapped to a dedicated API error response.