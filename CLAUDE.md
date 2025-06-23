# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🏃‍♂️ Quick Start Commands

### Most Common Development Commands
```bash
# Start development environment
make dev                          # Flutter Web with proper env vars

# Quality checks before committing
make test && make lint            # Run all tests and linting
make ci-test                      # Full CI pipeline locally

# Deployment
make deploy                       # Deploy both frontend and backend

# Reset when things break
make reset-dev                    # Clean rebuild of dev environment
```

### ADK Agent Development (NEW)
```bash
# Start ADK development server
cd backend/app
python -m adk.server --agent-path ./adk/agents --port 8080

# Test ADK agents
pytest tests/test_adk_agent.py -v

# Access ADK debug UI
# http://localhost:8080/adk/ui
```

### Flutter Web Development
```bash
cd frontend
flutter pub get                   # Install dependencies
flutter run -d chrome            # Start dev server
flutter test                     # Run tests
flutter analyze                  # Static analysis
```

### Backend Python Development
```bash
cd backend/app                    # Note: Changed from backend/functions
source venv/bin/activate         # Activate virtual environment
uvicorn app.main:app --reload    # Start FastAPI server
pytest                          # Run tests
black . && isort .              # Format code
```

## 🎯 Project Overview

**学校だよりAI** (School Newsletter AI) is an AI-powered web application that helps teachers create engaging, graphic-recording style school newsletters efficiently using voice input and AI assistance.

### Core Architecture Update: ADK Multi-Agent System
The project now uses Google's Agent Development Kit (ADK) to orchestrate multiple specialized agents:

```
User Voice Input → Orchestrator Agent → Planner Agent (Interactive Dialogue)
                                     ↓
                          Generator Agent → HTML/PDF Output
```

### Technology Stack
- **Frontend**: Flutter Web (PWA)
- **Backend**: FastAPI + Google ADK
- **AI Agents**: 
  - Google ADK for agent orchestration
  - Vertex AI Gemini 1.5 Pro for content generation
  - Google Speech-to-Text for voice input
- **Infrastructure**: Google Cloud Platform (Cloud Run, Firebase)
- **Editor**: Quill.js (Rich text editing)

## 📋 Development Rules & Architecture

### 🤖 ADK Agent Architecture (NEW)

#### Agent Hierarchy
1. **Orchestrator Agent** (`orchestrator_agent.py`)
   - Routes user commands (`/create`, `/edit`)
   - Manages workflow between agents
   - Handles artifact storage

2. **Planner Agent** (`planner_agent.py`)
   - Interactive dialogue with teachers
   - Gathers newsletter requirements
   - Generates structured requirements

3. **Generator Agent** (`generator_agent.py`)
   - Creates HTML content based on requirements
   - Applies graphic-recording style
   - Ensures print-friendly output

#### Tools vs Agents Design Philosophy
- **Tools**: Single-purpose, stateless functions
  - Examples: `DateTool`, `HtmlValidatorTool`, `SpeechToTextTool`
  - Use `@tool` decorator from ADK
  - No complex logic or state management

- **Agents**: Complex workflow managers
  - Multi-step processes with state
  - Error handling and retry logic
  - Coordinate multiple tools

### 🧪 TDD (Test-Driven Development) Required
All features must follow **Red → Green → Refactor** cycle:

1. **🔴 Red**: Write failing test first
2. **🟢 Green**: Implement minimum code to pass
3. **🔵 Refactor**: Improve code quality

**TDD Mandatory for**:
- ADK agents and tools
- API endpoints
- Core business logic
- UI components with complex state

### 📁 Project Structure
```
new-agent/
├── frontend/                    # Flutter Web PWA
│   ├── lib/
│   │   ├── app/                # App configuration
│   │   ├── core/               # Shared infrastructure
│   │   │   ├── models/         # Domain models
│   │   │   ├── services/       # API clients
│   │   │   └── theme/          # Design system
│   │   ├── features/           # Feature modules
│   │   │   ├── editor/         # Quill.js integration
│   │   │   ├── newsletter/     # Newsletter features (NEW)
│   │   │   └── ai_assistant/   # AI chat interface
│   │   └── main.dart          # Entry point
│   ├── web/
│   │   └── quill/index.html   # Quill.js bridge
│   └── test/                  # Flutter tests
├── backend/
│   ├── app/                    # FastAPI application
│   │   ├── adk/               # ADK implementation (NEW)
│   │   │   ├── agents/        # Multi-agent definitions
│   │   │   │   └── prompts/   # Agent instructions
│   │   │   └── tools/         # Single-purpose tools
│   │   ├── api/v1/endpoints/  # API routes
│   │   ├── models/            # Data models
│   │   └── services/          # Business logic
│   └── functions/             # Legacy Firebase Functions
└── docs/                      # Documentation
```

## 🎨 Coding Standards

### Python/FastAPI
```python
# ADK Tool Example
from adk import tool

@tool
async def get_current_date() -> str:
    """Returns current date in Japanese format."""
    return datetime.now().strftime("%Y年%m月%d日")

# ADK Agent Example
from adk import agent, llm

@agent
async def planner_agent(context: AgentContext) -> PlannerOutput:
    """Interactive planning agent for newsletter creation."""
    # Complex multi-step logic here
```

### Dart/Flutter
```dart
// Feature-based architecture
class NewsletterProvider extends ChangeNotifier {
  final AdkApiService _adkService;
  
  Future<void> createNewsletter(String voiceInput) async {
    try {
      final result = await _adkService.invokeAgent(
        agentId: 'orchestrator',
        input: {'command': '/create', 'voice': voiceInput},
      );
      notifyListeners();
    } catch (e) {
      _handleError('Newsletter creation failed: $e');
    }
  }
}
```

## 🚀 ADK-Specific Workflows

### Creating New ADK Tools
1. Add tool file to `backend/app/adk/tools/`
2. Use `@tool` decorator
3. Keep logic simple and stateless
4. Write unit tests

### Creating New ADK Agents
1. Add agent file to `backend/app/adk/agents/`
2. Create prompt in `agents/prompts/`
3. Use `@agent` decorator
4. Implement error handling
5. Write integration tests

### Testing ADK Components
```bash
# Unit test individual tools
pytest backend/app/tests/adk/tools/test_date_tool.py

# Integration test agent workflows
pytest backend/app/tests/adk/agents/test_orchestrator_agent.py

# End-to-end test with ADK server
python -m adk.test --agent orchestrator --scenario create_newsletter
```

## 🔧 Essential Development Commands

### Makefile Commands (Recommended)
```bash
make help                        # Show all available commands
make dev                         # Start development environment
make test                        # Run all tests
make lint                        # Run linting
make format                      # Auto-format code
make build-prod                  # Production build
make deploy                      # Deploy everything
make deploy-frontend             # Deploy frontend only
make deploy-backend              # Deploy backend only
```

### ADK Development Commands
```bash
# Start ADK server with hot reload
cd backend/app
adk serve --dev --port 8080

# Generate ADK tool from template
adk generate tool --name MyNewTool

# Validate agent definitions
adk validate ./adk/agents/

# Test agent conversation
adk chat --agent planner_agent
```

### Environment Configuration
The app uses dart-define for environment-specific configs:
- Development: `API_BASE_URL=http://localhost:8081/api/v1/ai`
- Staging: `API_BASE_URL=https://staging-yutori-backend.asia-northeast1.run.app/api/v1/ai`
- Production: `API_BASE_URL=https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai`

Always use `make dev` or `make staging` to ensure proper setup.

## 📊 Key Workflows

### Voice → Newsletter Creation Flow
1. **Voice Input**: Browser MediaRecorder API
2. **Speech-to-Text**: Google Cloud Speech-to-Text
3. **Orchestrator Agent**: Routes to appropriate workflow
4. **Planner Agent**: Interactive dialogue for requirements
5. **Generator Agent**: Creates HTML with Gemini
6. **Quill.js Editor**: Rich text editing
7. **PDF Export**: Print-optimized output

### ADK Agent Communication Flow
```
Frontend → /api/v1/adk/agent/invoke → Orchestrator Agent
                                           ↓
                                    Planner Agent ← → User (dialogue)
                                           ↓
                                    Generator Agent
                                           ↓
                                    HTML/PDF Output
```

## 🏗️ Architecture Decisions

### Why ADK?
- **Modularity**: Separate concerns into specialized agents
- **Maintainability**: Clear boundaries between components
- **Scalability**: Easy to add new agents/tools
- **User Experience**: Natural conversational interactions

### Tool vs Agent Guidelines
**Create a Tool when**:
- Single, well-defined purpose
- No state management needed
- Can complete in one step
- Reusable across agents

**Create an Agent when**:
- Multi-step workflow required
- Needs conversation/dialogue
- Requires complex decision logic
- Manages state between steps

## 🔒 Security & Best Practices

### API Security
- All endpoints require Firebase Authentication
- ADK agents validate user permissions
- Sensitive data never logged

### ADK Security
- Agent prompts sanitized for injection
- Tool inputs validated
- Session data encrypted

## 📚 Important Documentation

### Project Documentation
- [ADK API Best Practices](docs/ADK_API_BEST_PRACTICE.md) - ADK integration patterns
- [ADK Architecture Decision](docs/adr-0002-use-adk.md) - Why we chose ADK
- [Task Management](docs/tasks.md) - Project progress tracking

### External Resources
- [Google ADK Documentation](https://cloud.google.com/agent-development-kit)
- [Flutter Web Docs](https://flutter.dev/web)
- [FastAPI Documentation](https://fastapi.tiangolo.com)

## 🎯 Current Project Status

- **Project Phase**: ADK Integration Complete
- **Target**: Google Cloud Japan AI Hackathon Vol.2
- **Main Innovation**: Multi-agent system for natural teacher interactions
- **Goal**: Reduce newsletter creation from 2-3 hours to <20 minutes

## 🚦 Quick Troubleshooting

### ADK Issues
```bash
# Agent not responding
adk validate ./adk/agents/
adk logs --agent orchestrator --tail

# Tool errors
pytest backend/app/tests/adk/tools/ -v

# Session problems
redis-cli FLUSHDB  # Clear session cache
```

### Common Development Issues
```bash
# Flutter web issues
flutter clean && flutter pub get

# Python dependency issues
pip install -r requirements.txt --force-reinstall

# ADK server issues
lsof -i :8080  # Check if port is in use
```

---

**🤖 Note for Claude Code**

This project uses a sophisticated multi-agent architecture with Google ADK. When working on agent-related code:
1. Always check agent prompts in `backend/app/adk/agents/prompts/`
2. Follow the Tool vs Agent guidelines strictly
3. Test agent interactions using the ADK debug UI
4. Maintain conversational, teacher-friendly language in all agents

The ADK integration is the core innovation - treat it with care!