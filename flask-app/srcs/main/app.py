from flask import Flask, jsonify, request
from datetime import datetime
import os

app = Flask(__name__)

@app.route('/')
def hello_world():
    agent_name = os.getenv("AGENT_NAME", "Unknown")  # Get the agent name from the environment variable
    time = datetime.now().strftime("%H:%M")
    return jsonify({"message": f"Hello, my name is {agent_name} the time is {time}"})

@app.route('/health')
def health_check():
    return "Health check: OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
