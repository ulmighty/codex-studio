"""Fusion engine that combines voice, hand and gaze signals into intents."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional


@dataclass
class VoiceCommand:
    text: str


@dataclass
class HandState:
    x: float
    y: float
    z: float
    gesture: Optional[str] = None


@dataclass
class GazeState:
    quadrant: str


@dataclass
class FusedIntent:
    command: str
    target: Optional[str]
    context: Dict[str, float]


class FusionEngine:
    """Simple rule-based fusion of heterogeneous input signals."""

    def fuse(
        self, voice: VoiceCommand, hand: HandState, gaze: GazeState
    ) -> FusedIntent:
        """Combine inputs using heuristic rules.

        For demonstration purposes the algorithm is intentionally simple; a real
        implementation would incorporate timing windows and probabilistic
        weighting of confidence scores.  The returned :class:`FusedIntent`
        is deterministic which keeps the unit tests lightweight and fast.
        """

        target = gaze.quadrant if gaze.quadrant != "center" else None
        context = {"x": hand.x, "y": hand.y, "z": hand.z}
        command = voice.text.strip().lower()
        if hand.gesture:
            command = f"{command}:{hand.gesture}"
        return FusedIntent(command=command, target=target, context=context)
