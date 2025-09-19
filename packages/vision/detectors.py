"""Lightweight wrappers around YOLOv8 object detection.

Example
-------
>>> import numpy as np
>>> detector = YoloV8Detector("yolov8n.pt")
>>> frame = np.zeros((640, 640, 3), dtype=np.uint8)
>>> detections = detector.detect([frame])
>>> print(len(detections[0]))
"""

from __future__ import annotations
import logging
import threading
import time
from dataclasses import dataclass, field
from typing import Any, Dict, Iterable, List, Mapping, Optional, Sequence, Tuple, Union, TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover - only imported for typing
    import numpy as np

from ._device import resolve_device_config


LOGGER = logging.getLogger(__name__)


class VisionModelError(RuntimeError):
    """Raised when a detector fails to execute inference."""


@dataclass
class BoundingBox:
    """Axis aligned bounding box represented in corner format."""

    x1: float
    y1: float
    x2: float
    y2: float

    def as_tuple(self) -> Tuple[float, float, float, float]:
        """Return the bounding box coordinates as ``(x1, y1, x2, y2)``."""

        return (self.x1, self.y1, self.x2, self.y2)

    def width(self) -> float:
        """Width of the bounding box."""

        return float(self.x2 - self.x1)

    def height(self) -> float:
        """Height of the bounding box."""

        return float(self.y2 - self.y1)


@dataclass
class Detection:
    """Structured detection output."""

    bbox: BoundingBox
    score: float
    label: str
    track_id: Optional[int] = None
    extras: Dict[str, Any] = field(default_factory=dict)


def _coerce_int(value: Any, default: int) -> int:
    try:
        return int(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return default


class YoloV8Detector:
    """YOLOv8 detector wrapper that honours hardware tuning.

    Parameters
    ----------
    model_path:
        Local path to a YOLOv8 weights file understood by :mod:`ultralytics`.
    device:
        Device specifier forwarded to :meth:`ultralytics.YOLO.predict` (``"cpu"``
        by default).
    device_manager:
        Optional hardware tuner used to determine optimal ``image_size`` and
        ``batch_size``. The object is probed for ``get_inference_config``,
        ``resolve`` or ``get`` style methods before falling back to plain
        attribute access.
    confidence:
        Confidence threshold passed to the detector.
    iou:
        Intersection over union threshold used during non-maximum suppression.
    max_attempts:
        Number of inference retries before raising :class:`VisionModelError`.
    timeout:
        Maximum number of seconds allowed for all retries combined. ``None``
        disables the timeout.

    Example
    -------
    >>> from packages.vision.detectors import YoloV8Detector
    >>> detector = YoloV8Detector("yolov8n.pt")
    >>> dummy = [np.zeros((640, 640, 3), dtype=np.uint8)]  # doctest: +SKIP
    >>> results = detector.detect(dummy)  # doctest: +SKIP
    """

    def __init__(
        self,
        model_path: Union[str, "os.PathLike[str]"],
        *,
        device: Optional[str] = None,
        device_manager: Optional[Any] = None,
        confidence: float = 0.25,
        iou: float = 0.45,
        max_attempts: int = 3,
        timeout: Optional[float] = 10.0,
        detection_kwargs: Optional[Mapping[str, Any]] = None,
    ) -> None:
        self.model_path = str(model_path)
        self.device = device
        self.confidence = float(confidence)
        self.iou = float(iou)
        self.max_attempts = max(1, int(max_attempts))
        self.timeout = timeout
        self._detection_kwargs = dict(detection_kwargs or {})

        config = resolve_device_config(device_manager, "yolov8")
        self._image_size = _coerce_int(config.get("image_size"), 640)
        batch_value = config.get("batch_size", config.get("batch"))
        self._batch_size = max(1, _coerce_int(batch_value, 1))

        self._model = None
        self._model_lock = threading.Lock()

    def _ensure_model(self) -> Any:
        if self._model is not None:
            return self._model

        with self._model_lock:
            if self._model is None:
                self._model = self._load_model()
        return self._model

    def _load_model(self) -> Any:
        try:
            from ultralytics import YOLO  # type: ignore
        except Exception as exc:  # pragma: no cover - optional dependency
            raise VisionModelError("ultralytics is required for YOLOv8 inference") from exc

        try:
            model = YOLO(self.model_path)
        except Exception as exc:
            raise VisionModelError(f"Failed to load YOLOv8 weights from {self.model_path!r}") from exc

        if self.device:
            try:
                model.to(self.device)
            except Exception:  # pragma: no cover - best effort on optional dependency
                LOGGER.debug("Failed to move YOLO model to %s", self.device, exc_info=True)

        return model

    @staticmethod
    def _normalize_inputs(frames: Union[Sequence[Any], Any]) -> List[Any]:
        if isinstance(frames, Sequence) and not isinstance(frames, (bytes, bytearray, str)):
            return list(frames)

        return [frames]

    @staticmethod
    def _tensor_to_list(value: Any) -> List[float]:
        if value is None:
            return []
        if hasattr(value, "detach"):
            value = value.detach()
        if hasattr(value, "cpu"):
            value = value.cpu()
        if hasattr(value, "numpy"):
            value = value.numpy()
        if hasattr(value, "tolist"):
            return value.tolist()
        if isinstance(value, Iterable):
            return [float(v) for v in value]
        return [float(value)]

    def _convert_result(self, result: Any) -> List[Detection]:
        boxes = getattr(result, "boxes", None)
        labels: List[str] = []
        confidences: List[float] = []
        tracker_ids: List[Optional[int]] = []
        coordinates: List[List[float]] = []

        if boxes is not None:
            coordinates = self._tensor_to_list(getattr(boxes, "xyxy", None))
            confidences = [float(x) for x in self._tensor_to_list(getattr(boxes, "conf", None))]
            raw_labels = self._tensor_to_list(getattr(boxes, "cls", None))
            tracker_ids = [int(x) if x is not None else None for x in getattr(boxes, "id", [None] * len(raw_labels))]

            names = getattr(result, "names", None)
            if names is None and hasattr(result, "model"):
                names = getattr(result.model, "names", None)
            if names is None and hasattr(self._model, "names"):
                names = getattr(self._model, "names")

            label_map: Mapping[int, str]
            if isinstance(names, Mapping):
                label_map = {int(k): str(v) for k, v in names.items()}
            elif isinstance(names, Sequence):
                label_map = {idx: str(name) for idx, name in enumerate(names)}
            else:
                label_map = {}

            labels = [label_map.get(int(idx), str(int(idx))) for idx in raw_labels]
        elif isinstance(result, Sequence):  # Raw dictionary-like output
            for item in result:
                if not isinstance(item, Mapping):
                    continue
                bbox = item.get("bbox") or item.get("box")
                if bbox is None:
                    continue
                coordinates.append([float(v) for v in bbox])
                confidences.append(float(item.get("confidence", item.get("score", 0.0))))
                labels.append(str(item.get("label", "0")))
                tracker_ids.append(item.get("track_id"))
        else:  # pragma: no cover - fall back path for unexpected structure
            LOGGER.debug("Unknown YOLO result format: %s", type(result))

        detections: List[Detection] = []
        for idx, coord in enumerate(coordinates):
            if len(coord) < 4:
                continue
            bbox = BoundingBox(*[float(v) for v in coord[:4]])
            score = confidences[idx] if idx < len(confidences) else 0.0
            label = labels[idx] if idx < len(labels) else "0"
            track_id = tracker_ids[idx] if idx < len(tracker_ids) else None
            detections.append(Detection(bbox=bbox, score=score, label=label, track_id=track_id))
        return detections

    def detect(self, frames: Union[Sequence[Any], Any]) -> List[List[Detection]]:
        """Run batched detection with retry & timeout safety."""

        inputs = self._normalize_inputs(frames)

        deadline = time.monotonic() + self.timeout if self.timeout is not None else None
        attempts = 0
        last_error: Optional[Exception] = None

        while attempts < self.max_attempts:
            attempts += 1
            try:
                model = self._ensure_model()
                predictions = model.predict(  # type: ignore[operator]
                    inputs,
                    imgsz=self._image_size,
                    batch=self._batch_size,
                    device=self.device,
                    conf=self.confidence,
                    iou=self.iou,
                    verbose=False,
                    **self._detection_kwargs,
                )
                return [self._convert_result(result) for result in predictions]
            except Exception as exc:  # pragma: no cover - depends on runtime errors
                last_error = exc
                LOGGER.debug("YOLOv8 inference failed (attempt %s/%s)", attempts, self.max_attempts, exc_info=True)
                if deadline is not None and time.monotonic() >= deadline:
                    break
                if attempts >= self.max_attempts:
                    break
                time.sleep(min(0.5 * attempts, 1.5))

        raise VisionModelError("YOLOv8 inference failed") from last_error

    def __call__(self, frames: Union[Sequence[Any], Any]) -> List[List[Detection]]:
        return self.detect(frames)


__all__ = ["BoundingBox", "Detection", "VisionModelError", "YoloV8Detector"]
