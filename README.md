# SpecWise

**AI-Powered Software Requirements Engineering Platform**

SpecWise is a web-based platform designed to simplify and improve the Software Requirements Engineering process through AI-assisted requirement gathering, analysis, refinement, and documentation.

## Project Overview

Traditional requirements engineering often involves unclear requirements, incomplete information, and time-consuming documentation. SpecWise aims to address these challenges through an interactive, AI-assisted workflow.

The platform will allow users to describe their software ideas, refine requirements through AI-generated clarification questions, and produce structured Software Requirements Specification (SRS) documents.

## Planned Features

- Project creation and management
- AI-assisted requirements elicitation
- Interactive clarification questions
- Functional and non-functional requirements identification
- Requirements prioritization and refinement
- SRS document generation
- Specification version management
- Requirements review and approval

## Technology Stack

| Component | Technology |
|---|---|
| Frontend | React, TypeScript |
| Backend Automation | n8n |
| Database | PostgreSQL 17 |
| AI Integration | LLM APIs (planned) |
| Containerization | Docker |
| Version Control | Git and GitHub |

## Project Structure

```text
specwise-ai/
├── workflows/
│   └── 01-project-intake-api.json
├── database/
│   └── schema.sql
├── docs/
│   └── api-documentation.md
└── README.md
```

## Development Progress

### Workflow 1 — Project Intake API

**Status: Implemented and locally tested**

- Accepts project information through a REST webhook
- Validates project titles and initial ideas
- Uses header-based API-key authentication
- Saves valid projects in PostgreSQL
- Returns structured JSON responses
- Handles validation errors and database failures

### Upcoming Development

- AI requirements interviewer
- Requirements extraction and classification
- Clarification and refinement workflows
- SRS generation and versioning
- Review and approval functionality
- Frontend integration and user authentication

## API Endpoint

`POST /webhook/specwise/projects`

Request example:

```json
{
  "title": "Smart Attendance System",
  "initial_idea": "A university attendance management platform."
}
```

Authentication requires an `x-api-key` header, configured securely in n8n.

The API is currently tested in a local Docker environment. Public deployment and end-user authentication are not yet implemented.

## Current Status

SpecWise is under active development. The initial project intake workflow has been implemented and tested, while the remaining features are planned for subsequent development.

## Security

API credentials and database passwords are not included in this repository. Imported n8n workflows require their own credentials to be configured.

The API key is intended for trusted backend-to-backend communication and must not be embedded in public frontend code.

## License

MIT License.