from aura.providers.noise.rnnoise_local import RNNoiseLocal


def test_rnnoise_frame_size():
    ns = RNNoiseLocal()
    frame = b"\x00" * ns.frame_size
    assert ns.process(frame) == frame
