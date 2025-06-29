# Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /usr/src/app

# Install system dependencies
# wkhtmltopdf for pdfkit, Japanese fonts, and Playwright dependencies
RUN apt-get update && apt-get install -y \
    wkhtmltopdf \
    fonts-noto-cjk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install uv

# Copy dependency files
COPY pyproject.toml uv.lock /usr/src/app/

# Install dependencies using uv
# uv automatically handles the virtual environment in the container
RUN uv sync --no-dev

# Install Playwright browsers
RUN uv run playwright install chromium --with-deps

# Copy the rest of the application code
COPY . /usr/src/app

# Expose port
EXPOSE 8080

# Command to run the application
# The main app is located at app/main.py
CMD ["sh", "-c", "/usr/src/app/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]
