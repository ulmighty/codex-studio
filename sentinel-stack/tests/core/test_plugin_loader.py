from core.plugin_loader import load_plugins
from core.interfaces import PluginInterface


def test_load_plugins():
    plugins = load_plugins()
    assert plugins, "No plugins loaded"
    assert all(isinstance(p, PluginInterface) for p in plugins)
