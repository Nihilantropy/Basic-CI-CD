# Use an official Python runtime as the base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt file to the container
COPY requirements.txt /app/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application files to the container
COPY . /app/

# Set the environment variable for Flask
ENV FLASK_APP=main/app.py

# Expose the port that Flask will run on
EXPOSE 5000

# Run the Flask app when the container starts
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
