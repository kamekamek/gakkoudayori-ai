# Poetry to UV Migration Plan

## 📋 Migration Overview

This document outlines the migration plan from Poetry to UV package manager for the 学校だよりAI project.

## 🎯 Migration Benefits

### Performance Improvements
- **10-100x faster** dependency resolution
- **80x faster** virtual environment creation
- **Significantly lower** memory usage
- **Parallel downloads** and optimized caching

### Google ADK Compatibility
- Google officially supports UV for ADK projects
- Better alignment with Google's Python tooling recommendations
- Future-proof package management approach

## 📊 Current State Analysis

### Current Poetry Configuration
- **pyproject.toml**: Poetry-format configuration
- **poetry.lock**: Locked dependencies (152 total packages)
- **Makefile**: All commands use `poetry run` prefix
- **CI/CD**: GitHub Actions configured for Poetry

### Dependencies Overview
```toml
python = "^3.11"
google-adk = "^1.4.2"
fastapi = "*"
uvicorn = {extras = ["standard"], version = "*"}
# + 15 other production dependencies
# + 6 development dependencies
```

## 🚀 Migration Steps

### Phase 1: Pre-Migration Preparation
1. **Create migration branch**
   ```bash
   git checkout -b feature/migrate-to-uv
   ```

2. **Backup current state**
   ```bash
   cp pyproject.toml pyproject.toml.backup
   cp poetry.lock poetry.lock.backup
   ```

3. **Verify current functionality**
   ```bash
   make test && make lint
   ```

### Phase 2: UV Installation and Setup
1. **Install UV globally**
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   # or
   pip install uv
   ```

2. **Verify UV installation**
   ```bash
   uv --version
   ```

### Phase 3: Migration Execution
1. **Automatic migration using migrate-to-uv**
   ```bash
   uvx migrate-to-uv
   ```

2. **Manual pyproject.toml cleanup** (if needed)
   - Remove `[tool.poetry]` section
   - Ensure `[project]` section is properly configured
   - Keep tool configurations (black, isort, mypy, ruff, pytest)

3. **Create uv.lock file**
   ```bash
   uv lock
   ```

### Phase 4: Makefile Updates
Update all `poetry run` commands to `uv run`:

```makefile
# Before
cd backend && poetry run pytest tests/ -v

# After  
cd backend && uv run pytest tests/ -v
```

**Commands to update:**
- `backend-dev`: `poetry run uvicorn` → `uv run uvicorn`
- `test`: `poetry run pytest` → `uv run pytest`
- `lint`: `poetry run ruff/mypy` → `uv run ruff/mypy`
- `format`: `poetry run black/isort` → `uv run black/isort`
- `ci-setup`: `poetry install` → `uv sync`

### Phase 5: CI/CD Updates
Update GitHub Actions workflow:

```yaml
# Before
- name: Install dependencies
  run: cd backend && poetry install --with dev --no-root

# After
- name: Install dependencies
  run: cd backend && uv sync --dev
```

### Phase 6: Docker Updates
Update Dockerfile if needed:

```dockerfile
# Before
RUN poetry install --only=main --no-root

# After
RUN uv sync --no-dev
```

## 🧪 Testing Strategy

### Functionality Tests
1. **Development server startup**
   ```bash
   make backend-dev
   ```

2. **ADK agent functionality**
   ```bash
   make test-adk
   ```

3. **Full test suite**
   ```bash
   make test && make lint
   ```

4. **Build and deployment**
   ```bash
   make deploy-backend
   ```

### Performance Benchmarks
Compare before/after metrics:
- Dependency installation time
- Virtual environment creation time
- Memory usage during operations

## 🔧 Configuration Changes

### pyproject.toml Changes
```toml
# Remove Poetry-specific sections
[tool.poetry]          # DELETE
[tool.poetry.dependencies]  # DELETE
[tool.poetry.group.dev.dependencies]  # DELETE

# Add UV-compatible project section
[project]
name = "backend"
version = "0.1.0"
description = "Gakkoudayori AI Backend"
dependencies = [
    "fastapi",
    "uvicorn[standard]",
    "google-adk>=1.4.2",
    # ... other dependencies
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "mypy>=1.5.0",
    "ruff>=0.0.285",
    "black>=23.7.0",
    "isort>=5.12.0",
]
```

## 🚨 Risk Assessment

### High Risk
- **CI/CD Pipeline Failure**: Commands may fail if not properly updated
- **Dependency Conflicts**: Lock file differences could cause issues

### Medium Risk
- **Development Workflow Disruption**: Team needs to adapt to new commands
- **Docker Build Issues**: Container builds may need adjustment

### Low Risk
- **Local Development**: UV maintains compatibility with existing setups

## 📝 Rollback Plan

If migration fails:
1. **Restore backup files**
   ```bash
   mv pyproject.toml.backup pyproject.toml
   mv poetry.lock.backup poetry.lock
   ```

2. **Reinstall Poetry dependencies**
   ```bash
   poetry install --with dev --no-root
   ```

3. **Verify functionality**
   ```bash
   make test && make lint
   ```

## 📅 Timeline Estimate

- **Phase 1-2**: 30 minutes
- **Phase 3**: 15 minutes  
- **Phase 4-5**: 1 hour
- **Phase 6**: 30 minutes
- **Testing**: 1 hour
- **Total**: ~3 hours

## ✅ Success Criteria

- [ ] All existing functionality works correctly
- [ ] CI/CD pipeline passes
- [ ] ADK agents function properly
- [ ] Performance improvements are measurable
- [ ] Team can execute standard development workflows

## 📚 References

- [UV Documentation](https://docs.astral.sh/uv/)
- [migrate-to-uv Tool](https://github.com/pypa/migrate-to-uv)
- [Google ADK UV Support](https://google.github.io/adk-docs/)
- [Poetry to UV Migration Guide](https://stackoverflow.com/questions/79118841/how-can-i-migrate-from-poetry-to-uv-package-manager)

---

**Note**: This migration is planned but not executed. Current Poetry setup remains stable and functional.