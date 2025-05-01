#
# Dockerfile for ScraperAgent
# Uses Microsoft Playwright Python image with all browser dependencies installed.
#
FROM mcr.microsoft.com/playwright/python:latest

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# Download spaCy English model
RUN python -m spacy download en_core_web_sm

# Copy application code
COPY . .

# Set environment variable for Cloud Run
ENV PORT 8080

# Expose port for the FastAPI server
EXPOSE 8080

# Start the FastAPI server on the specified port
CMD ["sh", "-c", "uvicorn server:app --host 0.0.0.0 --port $PORT"]