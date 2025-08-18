Write-Host "Running Project Aura smoke check..."
# Basic checks for required modules and config
python - <<'PY'
import importlib
for mod in ["aura", "aura.providers.bodytracking.kinect_v2"]:
    importlib.import_module(mod)
print("Imports OK")
PY
