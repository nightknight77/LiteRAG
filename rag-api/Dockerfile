FROM python:3.11-slim

WORKDIR /app

# Install Poetry
RUN pip install --no-cache-dir poetry

# Configure Poetry to not use virtual environment
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VENV_IN_PROJECT=false \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Copy Poetry files
COPY pyproject.toml poetry.lock* ./

# Install dependencies
RUN poetry install --only=main --no-root && rm -rf $POETRY_CACHE_DIR

# Copy application code
COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]