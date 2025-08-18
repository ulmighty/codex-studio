# Security & Privacy Notes

- Telemetry is **disabled by default**. No data leaves the machine unless explicitly enabled.
- Logs and posture plans are stored locally using Windows DPAPI (stubbed in this reference implementation).
- Voice logs rotate based on `voice_log_retention_days` in `config.yaml`.
- A panic hotkey should be configured by the user to immediately stop input injection.
