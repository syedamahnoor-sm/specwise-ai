# SpecWise

### AI-Powered Software Requirements Engineering Platform

SpecWise is a full-stack AI application designed to transform initial software ideas into structured, developer-ready requirements through intelligent, interactive conversations.

## Project Vision

Software projects often begin with vague or incomplete requirements. SpecWise aims to bridge the gap between a client's idea and the technical specifications developers need to begin implementation.

## Planned Features

- AI-powered requirements gathering chatbot
- Intelligent follow-up questions and ambiguity detection
- Persistent project and conversation history
- Functional and non-functional requirements extraction
- Contradiction detection and requirement validation
- Structured JSON specification generation
- Software Requirements Specification (SRS) generation
- User stories and acceptance criteria
- Client review and approval workflow
- Developer-ready project handoff

## Planned Technology Stack

| Layer | Technology |
|---|---|
| Frontend | React, TypeScript, Tailwind CSS |
| Backend orchestration | n8n |
| AI | Gemini or Anthropic |
| Database | PostgreSQL |
| API communication | REST APIs and Webhooks |
| Development assistance | Claude Code |

## Architecture

Frontend → n8n Webhook APIs → AI Processing & Business Logic → PostgreSQL

## Project Status

**Planning and architecture phase.**

This project is being developed as part of hands-on Agentic AI learning, focusing on webhook automation, conversational AI, structured outputs, and full-stack integration.

**Note:** SpecWise does not use Retrieval-Augmented Generation (RAG). Its primary focus is interactive requirements elicitation and structured project-state management.

## License

MIT
