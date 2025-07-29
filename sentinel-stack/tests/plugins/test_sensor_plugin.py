from plugins.sensor_plugin.plugin import SensorPlugin


def test_health_status():
    plugin = SensorPlugin()
    plugin.start()
    assert plugin.get_health_status() == {"temp": 42}
    assert plugin.widget is not None
