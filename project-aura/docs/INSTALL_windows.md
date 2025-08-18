# Installation Guide (Windows)

1. Install **Python 3.9** and create a virtual environment:
   ```powershell
   py -3.9 -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```
2. Install **Kinect for Windows SDK v2** and ensure the sensor works using the Kinect Configuration Verifier.
3. Install **PyKinect2** (`pip install pykinect2`). The package requires 64-bit Python.
4. Install **OBS Studio** and the **VirtualCam** plugin for virtual camera support.
5. Obtain a **Picovoice Porcupine** access key and place your `.ppn` model file in a known location. Update `config.yaml` accordingly.
6. Run the smoke test:
   ```powershell
   powershell scripts/smoke_check.ps1
   ```
