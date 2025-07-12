# Official lightweight Python image
FROM python:3.11-slim

# Set ENV VARS
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# COPY project files
COPY . .

# Expose Flask port 5000
EXPOSE 5000

# Start the app
CMD ["python", "app.py"]