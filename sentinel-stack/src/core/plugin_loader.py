from importlib import import_module
from pathlib import Path
from typing import List

from .interfaces import PluginInterface


PLUGIN_PATH = Path(__file__).resolve().parent.parent / "plugins"


def load_plugins() -> List[PluginInterface]:
    """Discover and instantiate available plugins."""
    plugins: List[PluginInterface] = []
    for plugin_dir in PLUGIN_PATH.iterdir():
        if plugin_dir.is_dir() and (plugin_dir / "plugin.py").exists():
            module_name = f"plugins.{plugin_dir.name}.plugin"
            module = import_module(module_name)
            plugin_class = None
            for attr in dir(module):
                obj = getattr(module, attr)
                if isinstance(obj, type) and issubclass(obj, PluginInterface) and obj is not PluginInterface:
                    plugin_class = obj
                    break
            if plugin_class:
                plugins.append(plugin_class())
    return plugins
