# Official lightweight Python image
FROM python:3.11-slim

# Set ENV VARS
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create a non-root user
RUN addgroup --system pythongroup && adduser --system --ingroup pythongroup pythonuser

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app files
COPY . .

# Change ownership of the app directory
RUN chown -R pythonuser:pythongroup /app

# Switch to non-root user
USER pythonuser

# Expose Flask port
EXPOSE 5000

# Start the app
CMD ["python", "app.py"]