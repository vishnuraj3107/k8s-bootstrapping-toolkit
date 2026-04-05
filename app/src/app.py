"""
Sample Flask Application
Author: Vishnu Raj
Description: Lightweight Python web app to demonstrate 
             containerization and Kubernetes deployment
"""

from flask import Flask, jsonify
import os
import socket
import datetime

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
APP_ENV     = os.environ.get("APP_ENV", "production")


@app.route("/")
def index():
    return jsonify({
        "message": "Kubernetes Bootstrapping Toolkit - Sample App",
        "version": APP_VERSION,
        "environment": APP_ENV,
        "hostname": socket.gethostname(),
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
    })


@app.route("/health")
def health():
    """Liveness probe endpoint"""
    return jsonify({"status": "healthy"}), 200


@app.route("/ready")
def ready():
    """Readiness probe endpoint"""
    return jsonify({"status": "ready"}), 200


@app.route("/info")
def info():
    """App metadata for observability"""
    return jsonify({
        "app": "sample-app",
        "version": APP_VERSION,
        "env": APP_ENV,
        "pod": socket.gethostname(),
        "uptime": "running"
    })


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
