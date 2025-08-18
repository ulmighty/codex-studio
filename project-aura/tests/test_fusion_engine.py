from aura.core.fusion_engine import FusedIntent, FusionEngine, GazeState, HandState, VoiceCommand


def test_fusion_engine_basic():
    engine = FusionEngine()
    intent = engine.fuse(
        VoiceCommand("Select"),
        HandState(0.5, 0.5, 0.2, gesture="point"),
        GazeState("top_left"),
    )
    assert isinstance(intent, FusedIntent)
    assert intent.command == "select:point"
    assert intent.target == "top_left"
    assert intent.context["x"] == 0.5
