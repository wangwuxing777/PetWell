FROM python:3.10-slim

WORKDIR /app

# Copy requirement list
COPY Backend/requirements.txt ./

# Install pip dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy all the rest of the backend files
COPY Backend/ ./

# Expose port (Zeabur will map this automatically)
EXPOSE 8000

# Start FastAPI server
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
