# SpecWise API Documentation

## Common configuration

- Base URL (local): `http://localhost:5678`
- Content type: `application/json`
- Authentication: `x-api-key: YOUR_API_KEY` (n8n Header Auth)
- Published workflows: `/webhook/...`; n8n test listener: `/webhook-test/...`
- Never expose the API key in a public frontend or commit it to Git.

## Workflow 1 — Project Intake API

**Status:** Implemented and locally tested  
**Endpoint:** `POST /webhook/specwise/projects`

Creates a software project. Required fields: `title` (nonempty string, max 255 characters) and `initial_idea` (nonempty string, max 10,000 characters). Leading/trailing whitespace is trimmed.

### Example request

```json
{
  "title": "Smart Attendance System",
  "initial_idea": "A university attendance management system."
}
```

### Success — HTTP 201 (illustrative)

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

### Error handling

| HTTP | Condition |
|---|---|
| 400 | Invalid or missing title/initial idea |
| 403 | Missing/invalid API key (n8n authentication) |
| 503 | Database unavailable |

**Verified tests:** Valid creation (201); empty, non-string, and overlength title (400); missing initial idea (400); missing API key (403); database unavailable (503). SQL insertion is parameterized.

## Workflow 2 — AI Requirements Interviewer

**Status:** Implemented and locally tested  
**Endpoint:** `POST /webhook/specwise/projects/interview`

Validates an existing project, retrieves its pending clarification questions if present, or asks Gemini Flash-Lite to generate and persist 5–7 questions. Each question includes a category, priority, and initial `pending` status.

### Example request

```json
{
  "project_id": "0fe31450-7fc1-4070-a136-d38180b1a205"
}
```

### New questions — HTTP 201 (abbreviated example)

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

The example contains one question for readability; actual new interviews normally produce 5–7.

### Existing pending questions — HTTP 200

Returns `success: true`, `question_count`, and the existing saved question objects without another Gemini call.

### Error handling

| HTTP | Condition |
|---|---|
| 400 | Invalid/missing project UUID |
| 403 | Missing/invalid API key |
| 404 | Project not found |
| 503 | Gemini service or database unavailable |

Gemini failure example:

```json
{
  "success": false,
  "error": "AI_SERVICE_UNAVAILABLE",
  "message": "Unable to generate clarification questions right now. Please try again later.",
  "project_id": "5fe84315-94f6-424f-b67b-50136f02267f"
}
```

**Question categories:** `functional`, `non_functional`, `security`, `usability`, `performance`, `stakeholder`, `constraint`.  
**Priorities:** `high`, `medium`, `low`.

**Verified tests:** New-question generation and storage (201), pending-question reuse (200), Gemini failure handling (503). Duplicate avoidance covers sequential requests, not simultaneous requests. Malformed Gemini JSON has no dedicated error response.

## Workflow 3 — AI Chatbot Conversation

**Status:** Implemented and locally tested  
**Endpoint:** `POST /webhook/specwise/projects/chat`

Accepts an answer for a pending clarification question belonging to the specified project. Marks the question as `answered`, then returns the next pending question ordered by priority (`high`, `medium`, `low`) and ID. When no pending questions remain, returns `interview_complete: true`.

### Example request

```json
{
  "project_id": "0fe31450-7fc1-4070-a136-d38180b1a205",
  "question_id": "cdb3391e-80f6-4325-a9d1-2cb5f7d4ad83",
  "answer": "Students, teachers, and administrators will use the system."
}
```

| Field | Type | Validation |
|---|---|---|
| `project_id` | String | Required UUID |
| `question_id` | String | Required UUID |
| `answer` | String | Required, nonempty after trimming |

### Answer saved; next question available — HTTP 200

```json
{
  "success": true,
  "interview_complete": false,
  "message": "Answer saved successfully. Here is your next question.",
  "next_question": {
    "id": "11111111-1111-4111-8111-111111111111",
    "question": "What authentication methods are required?",
    "category": "security",
    "priority": "high"
  }
}
```

The `next_question` example is illustrative.

### Final answer; interview complete — HTTP 200

```json
{
  "success": true,
  "interview_complete": true,
  "message": "All clarification questions have been answered. Your requirements are ready for specification generation.",
  "next_question": null
}
```

### Invalid input — HTTP 400

```json
{
  "success": false,
  "message": "Invalid chat input.",
  "errors": ["Answer cannot be empty."]
}
```

### Missing or previously answered question — HTTP 404

```json
{
  "success": false,
  "error": "QUESTION_NOT_FOUND",
  "message": "The clarification question was not found or has already been answered."
}
```

### Concurrent update conflict — HTTP 409

```json
{
  "success": false,
  "error": "ANSWER_NOT_SAVED",
  "message": "The question may have already been answered. Please refresh and try again."
}
```

The `409` response is configured but **has not been exercised in a concurrent-request test**. A request for an already-answered question normally returns `404` at the initial verification step.

### Authentication failure — HTTP 403

n8n rejects requests without the correct Header Auth key before workflow execution.

### PostgreSQL operations

1. Select the question by `id`, `project_id`, and `status = 'pending'`.
2. Update `answer` and `status = 'answered'` only if the row is still pending, using parameterized SQL.
3. Select the next pending question by project and priority.

**Note:** The current workflow does **not** populate `answered_at` or insert into `conversations`. Both are future enhancements.

### Tests performed

| Scenario | Expected HTTP | Observed result |
|---|---|---|
| Submit valid answer | 200 | Passed |
| Save answer in PostgreSQL | — | Verified `answered` status |
| Return next pending question | 200 | Passed |
| Process remaining four questions | 200 | Passed |
| Last question returns `interview_complete: true` | 200 | Passed |
| All five question records marked `answered` | — | Verified in PostgreSQL |
| Empty answer | 400 | Reported passed |
| Nonexistent question | 404 | Passed |
| Already-answered question | 404 | Passed |
| Simultaneous-update conflict | 409 | Not tested |

### Known limitations

- No Gemini-generated contextual follow-up questions yet; planned for Workflow 4.
- No persisted chat transcript in `conversations` yet.
- No per-user authorization or production rate limiting.
- No dedicated database failure response branch in Workflow 3; a database error may result in n8n's default error handling.

## Importing workflows

1. Run `database/schema.sql` against PostgreSQL.
2. Import `workflows/01-project-intake-api.json`, `02-ai-requirements-interviewer.json`, and `03-ai-chatbot-conversation.json` into n8n.
3. Configure the required Header Auth and PostgreSQL credentials, plus Gemini credentials for Workflow 2.
4. Publish/activate the workflows and use the production webhook paths.
5. Review workflow exports for metadata and secrets before committing.
