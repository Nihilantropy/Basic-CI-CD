from flask import Flask, jsonify, request
from datetime import datetime
import os
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.DEBUG)

@app.route('/')
def hello_world():
    agent_name = os.getenv("AGENT_NAME", "Unknown")  # Get the agent name from the environment variable
    time = datetime.now().strftime("%H:%M")
    app.logger.debug(f"Handling / request, agent: {agent_name}, time: {time}")
    return jsonify({"message": f"Hello, my name is {agent_name} the time is {time}"})

@app.route('/health')
def health_check():
    app.logger.debug("Health check request received")
    return "Health check: OK", 200

if __name__ == '__main__':
    # Print a message indicating that the app is starting
    print("We are live!")
    app.logger.info("Flask application is starting...")
    app.run(host='0.0.0.0', port=5000)
