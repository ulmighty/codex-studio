"""Scene segmentation utilities powered by PySceneDetect.

Example
-------
>>> detector = SceneCutDetector()
>>> cuts = detector.detect("sample.mp4")  # doctest: +SKIP
"""

from __future__ import annotations

import logging
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, List, Mapping, Optional, Sequence, Tuple, Union

from ._device import resolve_device_config

LOGGER = logging.getLogger(__name__)


class SceneDetectionError(RuntimeError):
    """Raised when scene detection fails."""


@dataclass
class SceneCut:
    """Simple representation of a scene interval."""

    start_seconds: float
    end_seconds: float
    start_frame: Optional[int] = None
    end_frame: Optional[int] = None

    @property
    def duration(self) -> float:
        """Return the scene duration in seconds."""

        return max(0.0, float(self.end_seconds) - float(self.start_seconds))

    def as_tuple(self) -> Tuple[float, float]:
        """Return ``(start_seconds, end_seconds)`` for convenience."""

        return float(self.start_seconds), float(self.end_seconds)


class SceneCutDetector:
    """Detect hard cuts in a video using PySceneDetect."""

    def __init__(
        self,
        *,
        backend: str = "content",
        threshold: float = 27.0,
        min_scene_len: int = 15,
        device_manager: Optional[Any] = None,
        video_manager_options: Optional[Mapping[str, Any]] = None,
        max_attempts: int = 3,
        timeout: Optional[float] = 30.0,
    ) -> None:
        config = resolve_device_config(device_manager, "scenedetect")
        self.backend = str(config.get("backend", backend))
        self.threshold = float(config.get("threshold", threshold))
        self.min_scene_len = int(config.get("min_scene_len", min_scene_len))
        self.frame_skip = int(config.get("frame_skip", 0))
        self.downscale = int(config.get("downscale", config.get("downscale_factor", 1)))
        self.video_manager_options = dict(video_manager_options or {})
        if self.downscale > 1 and "downscale_factor" not in self.video_manager_options:
            self.video_manager_options["downscale_factor"] = self.downscale

        self.max_attempts = max(1, int(max_attempts))
        self.timeout = timeout

    def _make_detector(self) -> Any:
        try:
            from scenedetect.detectors import ContentDetector, ThresholdDetector
        except Exception as exc:  # pragma: no cover - optional dependency
            raise SceneDetectionError("PySceneDetect detectors are unavailable") from exc

        backend = self.backend.lower()
        if backend == "threshold":
            return ThresholdDetector(threshold=self.threshold, min_scene_len=self.min_scene_len)
        return ContentDetector(threshold=self.threshold, min_scene_len=self.min_scene_len)

    @staticmethod
    def _convert_scene(scene: Sequence[Any]) -> SceneCut:
        start, end = scene
        start_seconds = float(getattr(start, "get_seconds", lambda: start)())
        end_seconds = float(getattr(end, "get_seconds", lambda: end)())
        start_frame = getattr(start, "get_frames", lambda: None)()
        end_frame = getattr(end, "get_frames", lambda: None)()
        return SceneCut(
            start_seconds=start_seconds,
            end_seconds=end_seconds,
            start_frame=start_frame,
            end_frame=end_frame,
        )

    def detect(self, video: Union[str, Path], *, frame_skip: Optional[int] = None) -> List[SceneCut]:
        """Detect scenes in ``video`` with retries and timeout."""

        video_path = str(video)
        skip = self.frame_skip if frame_skip is None else int(frame_skip)
        options = dict(self.video_manager_options)

        deadline = time.monotonic() + self.timeout if self.timeout is not None else None
        attempts = 0
        last_error: Optional[Exception] = None

        while attempts < self.max_attempts:
            attempts += 1
            try:
                from scenedetect import SceneManager, open_video
            except Exception as exc:  # pragma: no cover - optional dependency
                raise SceneDetectionError("PySceneDetect is required") from exc

            try:
                scene_manager = SceneManager()
                scene_manager.add_detector(self._make_detector())
                video_manager = open_video(video_path, **options)
                try:
                    scene_manager.detect_scenes(video_manager, frame_skip=skip)
                finally:
                    video_manager.release()
                scenes = scene_manager.get_scene_list()
                return [self._convert_scene(scene) for scene in scenes]
            except Exception as exc:  # pragma: no cover - depends on runtime errors
                last_error = exc
                LOGGER.debug("Scene detection failed (attempt %s/%s)", attempts, self.max_attempts, exc_info=True)
                if deadline is not None and time.monotonic() >= deadline:
                    break
                if attempts >= self.max_attempts:
                    break
                time.sleep(min(0.5 * attempts, 1.5))

        raise SceneDetectionError("Failed to detect scenes") from last_error

    def __call__(self, video: Union[str, Path], *, frame_skip: Optional[int] = None) -> List[SceneCut]:
        return self.detect(video, frame_skip=frame_skip)


__all__ = ["SceneCut", "SceneCutDetector", "SceneDetectionError"]
