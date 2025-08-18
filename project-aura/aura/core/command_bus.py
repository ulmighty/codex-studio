"""Simple publish/subscribe command bus used by Project Aura."""
from __future__ import annotations

from collections import defaultdict
from typing import Callable, DefaultDict, List

Callback = Callable[[str, dict[str, object]], None]


class CommandBus:
    """In-process pub/sub message dispatcher."""

    def __init__(self) -> None:
        self._subscribers: DefaultDict[str, List[Callback]] = defaultdict(list)

    def subscribe(self, topic: str, callback: Callback) -> None:
        self._subscribers[topic].append(callback)

    def publish(self, topic: str, payload: dict[str, object]) -> None:
        for cb in list(self._subscribers.get(topic, [])):
            cb(topic, payload)
