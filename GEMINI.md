# GEMINI.md

This file provides concise guidance for Gemini CLI when working with this school newsletter AI project.

## 🚀 Project Overview

**学校だよりAI** - AI-powered web app helping teachers create graphic-recording style newsletters using voice input and multi-agent AI system.

**Tech Stack**: Flutter Web + FastAPI + Google ADK + Vertex AI Gemini 1.5 Pro

**Core Flow**: Voice Input → Orchestrator Agent → Planner Agent → Generator Agent → HTML/PDF Output

## 📋 Critical Work Process

### ⚠️ MANDATORY: Implementation Planning
**Before ANY implementation work**:
1. **Create detailed plan** with specific steps and acceptance criteria
2. **Generate checklist** with verification points for each component
3. **Present plan to user** and get explicit approval before proceeding
4. **Never start coding** without confirmed user approval of the plan

### Example Planning Template:
```
## Implementation Plan: [Feature Name]

### Overview
Brief description of what will be implemented

### Detailed Steps
1. Step 1 - Specific action with expected outcome
2. Step 2 - Another specific action
3. ...

### Acceptance Criteria
- [ ] Criterion 1 - How to verify success
- [ ] Criterion 2 - Another verification point
- [ ] Criterion 3 - Final validation

### Risk Assessment
- Potential issue 1 and mitigation
- Potential issue 2 and mitigation

**Please confirm this plan before I proceed with implementation.**
```

## 🏗️ Architecture Essentials

### ADK Multi-Agent System
- **Orchestrator Agent**: Routes commands (`/create`, `/edit`)
- **Planner Agent**: Interactive dialogue with teachers
- **Generator Agent**: Creates HTML content with graphic-recording style

### Tools vs Agents
- **Tools**: Single-purpose, stateless (`@tool` decorator)
- **Agents**: Multi-step workflows with state (`@agent` decorator)

### Project Structure
```
new-agent/
├── frontend/lib/
│   ├── features/ai_assistant/    # ADK chat interface
│   ├── features/editor/          # Quill.js integration
│   └── core/                     # Shared components
├── backend/app/
│   ├── adk/agents/              # Agent definitions
│   ├── adk/tools/               # Tool definitions
│   └── api/v1/endpoints/        # API routes
```

## 🔧 Essential Commands

### Development
```bash
make dev                    # Start both frontend and backend
make backend-dev           # Backend only (port 8081)
flutter run -d chrome     # Frontend only
```

### Quality Checks
```bash
make test && make lint     # Run tests and linting
flutter analyze           # Flutter static analysis
pytest                    # Python tests
```

### Environment
- Development: `API_BASE_URL=http://localhost:8081/api/v1/ai`
- Always use proper environment variables via dart-define

## 🎨 Coding Standards

### Python/FastAPI
```python
@tool
async def example_tool() -> str:
    """Single-purpose, stateless function."""
    return "result"

@agent
async def example_agent(context: AgentContext):
    """Complex workflow with state management."""
    pass
```

### Dart/Flutter
```dart
class ExampleProvider extends ChangeNotifier {
  Future<void> exampleMethod() async {
    try {
      // Implementation
      notifyListeners();
    } catch (e) {
      _errorProvider.setError('Error: $e');
    }
  }
}
```

## 🧪 TDD Requirements

**Mandatory TDD for**:
- ADK agents and tools
- API endpoints
- Core business logic
- Complex UI components

**Process**: Red (failing test) → Green (minimal implementation) → Refactor

## 🔒 Security & Best Practices

- Firebase Authentication required for all endpoints
- HTML sanitization (DOMPurify) for user content
- No eval() usage in JavaScript
- Input validation for all agent/tool parameters
- CORS properly configured for development

## 🚦 Troubleshooting

### Common Issues
```bash
# Port conflicts
lsof -i :8081 && kill [PID]

# Flutter compilation errors
flutter clean && flutter pub get

# ADK agent issues
adk validate ./adk/agents/
```

### Current Status
- ✅ Backend server running (port 8081)
- ✅ Frontend compilation working
- ✅ ADK multi-agent system integrated
- ✅ Error handling simplified
- ✅ Development environment functional

---

**🤖 Note for Gemini**

1. **ALWAYS create implementation plans first** - No coding without user approval
2. Follow ADK Tool vs Agent guidelines strictly
3. Maintain teacher-friendly conversational language in agents
4. Test ADK interactions using debug UI
5. The multi-agent architecture is the core innovation - handle with care

**Remember**: Plan first, code second, verify always.