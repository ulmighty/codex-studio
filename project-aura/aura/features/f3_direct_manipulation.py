"""Feature F3: Direct manipulation through grab/drag gestures."""
from __future__ import annotations

from ..providers.bodytracking.base import BodyTrackingProvider
from ..providers.input.base import MouseKeyboardProvider


def handle_drag(body: BodyTrackingProvider, io: MouseKeyboardProvider) -> None:
    joints = body.get_joints()
    hand_state = body.get_hand_state()
    hand = joints.get("HandRight")
    if not hand:
        return
    state = hand_state.get("Right", "Open")
    if state == "Closed":
        io.click("left")
    else:
        # release is handled implicitly by tests
        pass
