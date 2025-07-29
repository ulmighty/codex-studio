# 🛡️ SentinelStack

SentinelStack is a modular PyQt6 dashboard for Windows systems. It supports plugin-based extensions, data logging to PostgreSQL, and optional AI-driven anomaly detection.

## Features
- Plugin architecture for sensors and dashboards
- Basic PyQt6 GUI with plugin panels
- Logging to the `logs/` directory

## Installation
```bash
pip install -r requirements.txt
```

## Running
```bash
python src/core/main.py
```

## Project Structure
```
sentinel-stack/
├── src/
│   ├── core/
│   ├── plugins/
├── tests/
├── logs/
```

## Development
- Ensure `pytest` passes before committing.
- Refer to `AGENTS.md` for contributor guidelines.
