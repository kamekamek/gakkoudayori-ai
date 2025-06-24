# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🏃‍♂️ Quick Start Commands

For immediate productivity, use these essential commands:

### Most Common Commands
```bash
# Start development with proper environment
make dev

# Run all tests and checks (before committing)
make test && make lint

# Deploy everything (backend + frontend)
make deploy

# Reset development environment when things break
make reset-dev

# Full CI pipeline locally (before commits)
make ci-test
```

### Flutter Web Development
```bash
cd frontend
flutter pub get                    # Install dependencies
flutter run -d chrome             # Start dev server
flutter test                      # Run tests
flutter analyze                   # Static analysis
```

### Backend Python Development
```bash
cd backend
source venv/bin/activate          # Activate virtual environment
make backend-dev                  # Start local server with ADK
pytest                           # Run tests
flake8 . && black .              # Lint and format
```

## 🎯 Project Overview

**学校だよりAI (Gakkoudayori AI)** - An AI-powered school newsletter generation system that reduces creation time from 2-3 hours to under 20 minutes. Built for Google Cloud Japan AI Hackathon Vol.2.

### Core Architecture
```
Flutter Web (Frontend) 
    ↓ API
FastAPI + Google ADK (Backend)
    ↓
├─ Google Vertex AI (Gemini 2.0 Flash)
├─ Google Speech-to-Text V2
├─ Firebase (Auth, Firestore, Storage)
└─ WeasyPrint (PDF Generation)
```

### Key Technology Stack
- **Frontend**: Flutter Web (PWA)
- **Backend**: Python FastAPI + Google ADK
- **AI Framework**: Google Agent Development Kit (ADK)
- **AI Models**: Gemini 2.0 Flash (Text), Speech-to-Text V2
- **Infrastructure**: Google Cloud Run, Firebase
- **PDF**: WeasyPrint with Japanese font support

## 🤖 ADK (Agent Development Kit) Integration

This project uses Google's ADK for a multi-agent AI system:

### Agent Architecture
```
OrchestratorAgent (Main Coordinator)
    ├─ PlannerAgent (Content Structure)
    └─ GeneratorAgent (HTML Layout)
```

### ADK Development Guidelines
1. **Session Management**: Use ADK's standard Session model with timezone-aware datetime
2. **Agent Communication**: Data flows only through session history, no direct agent-to-agent calls
3. **Error Handling**: SSE responses must include `\n\n` delimiter
4. **Tool Design**: Tools handle external interactions, agents handle logic
5. **Prompt Engineering**: Be explicit and concrete in agent instructions

### ADK Best Practices
- Single FastAPI server with ADK integration (recommended approach)
- Use `transfer_to_agent` with only `agent_name` parameter
- Implement proper SSE streaming for real-time updates
- Always use session-based state management
- Follow the ADK workflow guide in `docs/guides/adk-workflow.md`

## 📁 Project Structure

### Frontend (Flutter Web)
```
frontend/
├── lib/
│   ├── app/                # Application configuration
│   ├── core/              # Shared infrastructure
│   │   ├── models/        # Domain models
│   │   ├── router/        # App routing
│   │   └── theme/         # Design system
│   ├── features/          # Feature-based modules
│   │   ├── ai_assistant/  # ADK chat interface
│   │   ├── editor/        # Newsletter editor
│   │   └── home/          # Main dashboard
│   ├── services/          # API and external services
│   └── widgets/           # Reusable components
├── web/                   # Web-specific assets
│   ├── audio-processor.js # Audio recording
│   └── index.html        # PWA configuration
└── test/                  # Test files
```

### Backend (Python FastAPI + ADK)
```
backend/
├── app/
│   ├── adk/               # ADK Integration
│   │   ├── agents/        # AI Agents
│   │   │   ├── orchestrator_agent.py
│   │   │   ├── planner_agent.py
│   │   │   └── generator_agent.py
│   │   └── tools/         # ADK Tools
│   ├── api/v1/           # API Endpoints
│   ├── services/         # Business Logic
│   │   ├── adk_session_service.py
│   │   ├── speech_recognition_service.py
│   │   ├── pdf_generator.py
│   │   └── newsletter_generator.py
│   └── prompts/          # AI Prompts
│       ├── classic/      # Traditional style
│       └── modern/       # Infographic style
├── tests/                # Test files
└── Makefile             # Development commands
```

## 🛠️ Development Commands

### Essential Makefile Commands
```bash
# Development
make help               # Show all available commands
make dev                # Start full dev environment
make backend-dev        # Backend only (port 8081)
make staging           # Test with staging environment

# Testing & Quality
make test              # Run all tests
make lint              # Static analysis
make format            # Auto-format code
make ci-test           # Full CI pipeline

# Deployment
make build-prod        # Production build
make deploy            # Deploy everything (RECOMMENDED)
make deploy-backend    # Backend only
make deploy-frontend   # Frontend only

# Utilities
make clean             # Clean build artifacts
make reset-dev         # Reset development environment
make logs              # View Cloud Run logs
```

### Environment Variables (Critical!)
The application uses dart-define for environment configuration:
```bash
# Development (default with 'make dev')
API_BASE_URL=http://localhost:8081/api/v1/ai

# Staging (with 'make staging')
API_BASE_URL=https://staging-yutori-backend.asia-northeast1.run.app/api/v1/ai

# Production (with 'make build-prod')
API_BASE_URL=https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai
```

**⚠️ Always use Makefile commands to ensure proper environment setup!**

## 📋 Development Guidelines

### TDD (Test-Driven Development) Required
Follow Red → Green → Refactor cycle for all features:
1. **🔴 Red**: Write failing test first
2. **🟢 Green**: Implement minimal code to pass
3. **🔵 Refactor**: Improve code quality

### Code Style
**Flutter/Dart**:
- Naming: `lowerCamelCase` (functions), `UpperCamelCase` (classes)
- Files: `snake_case.dart`
- State Management: Provider pattern
- Error Handling: Proper try-catch with user-friendly messages

**Python/FastAPI**:
- Naming: `snake_case` (functions), `PascalCase` (classes)
- Type hints: Required (Python 3.9+ syntax)
- Docstrings: Required for public functions
- Error Handling: HTTPException with appropriate status codes

### Document Management Rules
Based on `.cursor/rules/document_management.mdc`:
- File naming: `{Number}_{CATEGORY}_{title}.md`
- Categories: REQUIREMENT (01-09), DESIGN (10-19), SPEC (20-29), API (30-39)
- Include TL;DR section for quick understanding
- Keep documents under 10KB
- Add metadata: complexity, reading time, dependencies

## 🚀 Key Features & User Flow

### 1-Minute Newsletter Creation Flow
1. **Voice Input**: One-tap recording with noise cancellation
2. **AI Processing**: Multi-agent system structures content
3. **Preview & Edit**: WYSIWYG editor with print preview
4. **Export**: High-quality PDF with Japanese fonts

### Two Style Options
- **Classic**: Traditional newsletter layout
- **Modern**: Infographic-style design

### Advanced Features
- User dictionary for school-specific terms
- Seasonal themes and templates
- Mobile-responsive A4 preview
- Real-time collaboration (future)

## 🧪 Testing Strategy

### Frontend Testing
```bash
cd frontend
flutter test                    # Unit tests
flutter test integration_test/  # Integration tests
flutter test --coverage        # Coverage report
```

### Backend Testing
```bash
cd backend
pytest                         # All tests
pytest -v tests/test_adk/      # ADK-specific tests
pytest --cov=app --cov-report=html  # Coverage report
```

### E2E Testing
```bash
cd frontend/e2e
npm install
npm run test                   # Playwright tests
```

## 🔍 Troubleshooting

### Common ADK Issues
1. **Session ID errors**: Ensure timezone-aware datetime usage
2. **SSE streaming fails**: Check for `\n\n` delimiter in responses
3. **Agent communication errors**: Verify session history is properly maintained
4. **Tool execution fails**: Check tool parameter schemas match exactly

See `docs/guides/adk-troubleshooting-guide.md` for detailed solutions.

### Frontend Issues
1. **API connection fails**: Verify environment variables with `make dev`
2. **Audio recording issues**: Check browser permissions and HTTPS
3. **PDF generation timeout**: Reduce content complexity or increase timeout

### Backend Issues
1. **ADK import errors**: Ensure `google-genai-adk` is installed
2. **Vertex AI quota**: Check project quotas in GCP console
3. **Memory issues**: Monitor Cloud Run instance memory usage

## 📚 Important Documentation

### Project Documentation
- `docs/HACKATHON_RULES.md` - Competition requirements
- `docs/PROJECT_COMPLETION_REPORT.md` - Final submission details
- `docs/archive/PROJECT_COMPLETION_SUMMARY.md` - Technical summary

### ADK Guides
- `docs/guides/adk-workflow.md` - Agent design workflow
- `docs/guides/adk-implementation-checklist.md` - Implementation checklist
- `docs/guides/adk-lessons-learned.md` - Pitfalls and solutions
- `backend/ADK_API_BEST_PRACTICE.md` - API integration patterns

### Architecture Decisions
- `docs/adr/adr-0001-frontend-architecture.md` - Flutter architecture
- `docs/adr/adr-0002-use-adk.md` - ADK adoption rationale

## 🏁 Project Status

**Status**: ✅ Completed and submitted for Google Cloud Japan AI Hackathon Vol.2

### Achievements
- 1-minute newsletter creation (goal: <20 minutes) ✅
- Multi-agent AI system with ADK ✅
- Two style options (Classic/Modern) ✅
- Production deployment on GCP ✅
- All 62 tasks completed ✅

### Performance Metrics
- Newsletter generation: ~60 seconds
- API response time: <500ms
- PDF generation: <3 seconds
- Speech recognition accuracy: >95%

## 🤝 Contributing Guidelines

### Before Starting
1. Read this CLAUDE.md thoroughly
2. Check `docs/guides/` for ADK patterns
3. Use `make dev` for proper environment setup
4. Follow TDD principles

### Code Review Checklist
- [ ] Tests pass (`make test`)
- [ ] Linting clean (`make lint`)
- [ ] ADK patterns followed
- [ ] Error handling implemented
- [ ] Documentation updated
- [ ] Performance acceptable

### Commit Message Format
```
[category] Brief description

Detailed explanation if needed

- Change 1
- Change 2

Fixes: #issue-number
```

Categories: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## 🎓 Learning Resources

### ADK Resources
- [Google ADK Documentation](https://ai.google.dev/agentic/agent-development-kit)
- [Vertex AI Gemini Docs](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- ADK examples in `backend/app/adk/`

### Flutter Resources
- [Flutter Web Docs](https://flutter.dev/web)
- [Provider Package](https://pub.dev/packages/provider)
- Widget examples in `frontend/lib/widgets/`

### Project-Specific
- Prompts in `backend/app/prompts/`
- Agent implementations in `backend/app/adk/agents/`
- UI components in `frontend/lib/features/`

---

## 🤖 Message to Claude Code

This is an education-focused application helping teachers create engaging newsletters efficiently. The codebase uses Google's ADK for multi-agent AI orchestration, which is a key differentiator.

**Key points to remember**:
1. Always use `make` commands for consistency
2. ADK agents communicate through session history only
3. The project is complete but can be enhanced
4. Focus on teacher usability and education needs
5. Test everything - this is production code

**When working on this project**:
- Check ADK guides before modifying agents
- Use proper environment variables via Makefile
- Follow the established patterns in the codebase
- Consider performance impacts on Cloud Run
- Keep the 1-minute workflow goal in mind

Welcome to 学校だよりAI! 🎉