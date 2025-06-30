# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED 1
ENV APP_HOME /app
# Set the default port. Cloud Run will override this with its own $PORT.
ENV PORT 8081
WORKDIR $APP_HOME

# Install system dependencies and uv in one step
RUN apt-get update && apt-get install -y curl && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx && \
    rm -rf /var/lib/apt/lists/* && \
    uv --version

# Copy only the dependency files first to leverage Docker layer caching
COPY pyproject.toml uv.lock ./

# Create virtual environment and install dependencies using uv sync
RUN uv venv /opt/venv && \
    uv sync --extra dev

# Set environment to use the virtual environment  
ENV PATH="/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV="/opt/venv"

# Copy the rest of the application code
COPY . .

# Expose the port the app runs on
EXPOSE ${PORT}

# Run the application using gunicorn from virtual environment
CMD ["/opt/venv/bin/gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "app.main:app", "--bind", "0.0.0.0:8081"]