from aura.features.f2_air_mouse import AirMouse, AirMouseConfig
from aura.providers.bodytracking.kinect_v2 import KinectV2Provider
from aura.providers.input.win_mousekbd import WinMouseKeyboardProvider


def test_air_mouse_moves_and_clicks():
    body = KinectV2Provider()
    io = WinMouseKeyboardProvider()
    config = AirMouseConfig(z_push_mm=0.6, z_pull_mm=0.8, smoothing=3)
    mouse = AirMouse(body, io, config)
    mouse.update()
    assert io.last_move != (0, 0)
    assert io.last_click == "left"
