from pathlib import Path

from aura.features.f5_app_awareness import ProfileManager, active_profile
from aura.providers.appaware.win32_foreground import Win32ForegroundProvider


def test_profile_manager_loads_profiles(tmp_path: Path):
    manager = ProfileManager(tmp_path)
    provider = Win32ForegroundProvider()
    (tmp_path / 'default_app_profile.yaml').write_text('name: default')
    profile = active_profile(provider, manager)
    assert profile['name'] == 'default'
