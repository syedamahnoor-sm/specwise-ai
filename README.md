# SpecWise

**AI-Powered Software Requirements Engineering Platform**

SpecWise helps turn initial software ideas into structured requirements through AI-generated clarification questions, a question-and-answer interview API, and planned specification generation and approval workflows.

## Current implementation

| Workflow | Description | Status |
|---|---|---|
| 1 — Project Intake API | Authenticated project creation and validation | Implemented and locally tested |
| 2 — AI Requirements Interviewer | Gemini-generated, categorized and prioritized clarification questions | Implemented and locally tested |
| 3 — AI Chatbot Conversation | Accept answers, mark questions answered, return next question, detect interview completion | Implemented and locally tested |
| 4 — Gemini Follow-up Questions & Conversation History | Gemini answer analysis, targeted follow-up generation, conversation history, idempotent processing | Implemented; positive and duplicate paths tested; other branches pending |
| 5 — Requirements Validation & SRS Generation | Extract and validate requirements, generate SRS | Planned |
| 6 — Document Generation & Export | Produce downloadable deliverables | Planned |
| 7 — Approval & Revision | Review, approve, revise and version specifications | Planned |

Workflow 3 is a sequential Q&A API, **not a free-form Gemini chatbot**. Workflow 4 separately analyzes answered questions and may create a targeted follow-up. It is invoked explicitly and does not automatically run after Workflow 3.

## Implemented API endpoints

| Method | Production path | Function |
|---|---|---|
| POST | `/webhook/specwise/projects` | Create a project |
| POST | `/webhook/specwise/projects/interview` | Generate or retrieve clarification questions |
| POST | `/webhook/specwise/projects/chat` | Submit an answer and receive the next question or completion status |
| POST | `/webhook/specwise/projects/followup` | Analyze an answered question; create or retrieve a follow-up result |

All endpoints use n8n Header Auth (`x-api-key`) for trusted backend-to-backend requests. Do not embed this key in a browser application.

## Technology stack

| Component | Technology |
|---|---|
| Workflow/API automation | n8n |
| Database | PostgreSQL 17 |
| AI question generation | Google Gemini Flash-Lite (configured in n8n) |
| Containers | Docker |
| API transport | REST / JSON |
| Planned frontend | React and TypeScript |
| Version control | Git / GitHub |

## Repository structure

```text
specwise-ai/
├── workflows/
│   ├── 01-project-intake-api.json
│   ├── 02-ai-requirements-interviewer.json
│   ├── 03-ai-chatbot-conversation.json
│   └── 04-gemini-followup-conversation.json
├── database/
│   └── schema.sql
├── docs/
│   └── api-documentation.md
└── README.md
```

## Local setup

1. Start PostgreSQL and n8n in Docker.
2. Initialize the `specwise` database with `database/schema.sql` (the SQL includes idempotent migrations for question metadata).
3. Import all four workflow JSON files into n8n.
4. Reconnect PostgreSQL, Gemini (Workflows 2 and 4), and Header Auth credentials.
5. Publish/activate the workflows.
6. Send JSON requests to the endpoints using an HTTP client. The test endpoints use `/webhook-test/` while n8n listens for a test event.

See [`docs/api-documentation.md`](docs/api-documentation.md) for payloads, responses, and testing details.

## Verified development progress

- **Workflow 1:** Project creation, validation, missing-key rejection, and database failure handling tested.
- **Workflow 2:** Initial AI question generation, existing pending-question reuse, persistence, and AI failure handling tested.
- **Workflow 3:** Answer persistence and status update, next-question retrieval, full five-question interview completion, invalid-answer rejection, nonexistent-question rejection, and duplicate-answer rejection tested.
- **Workflow 4:** Follow-up generation and repeat-request retrieval tested with the same persisted follow-up ID. Prompt mapping corrected to read the original answer from `Get Answered Question`.
- **Not yet tested:** Workflow 4 no-follow-up branch, concurrency and failure recovery; Workflow 3 simultaneous-update HTTP 409 conflict scenario.

## Known limitations

- Workflow 3 does not currently write records to the `conversations` table or set `clarification_questions.answered_at`. Workflow 4 records the original question and answer in `conversations` when processing a follow-up decision.
- Workflow 4 is a separate API call; follow-up generation is not automatically triggered by Workflow 3.
- API-key authentication is not a substitute for user-level authentication and per-project authorization.
- Rate limiting, production deployment, and frontend integration are pending.
- Workflow 2's malformed-model-output handling and concurrent duplicate-generation safeguards need further hardening.

## Workflow 4 operational notes

- `followup_processing.question_id` has a unique constraint so repeated requests retrieve the existing result instead of generating another question.
- The positive and no-follow-up paths use single-statement PostgreSQL data-modifying CTEs to save history and finalize processing atomically.
- Gemini prompt must reference `$('Get Answered Question').first().json` for project and question context, not the current `$json` after the claim node.
- A processing claim stuck in `processing` after an unexpected failure requires operator review; automatic stale-claim recovery is not yet implemented.
- Export and review the **actual** Workflow 4 JSON from n8n before committing; this documentation package does not include that export.

## Security

Never commit API keys, Gemini credentials, database passwords, or `.env` files. Exported n8n workflows contain credential references and instance metadata; review and sanitize them before publishing. Rotate any credentials that were previously exposed.

## License

MIT License.
