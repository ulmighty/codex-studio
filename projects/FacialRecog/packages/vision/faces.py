"""InsightFace based face detection and embedding utilities.

Example
-------
>>> import numpy as np
>>> pipeline = InsightFacePipeline(
...     det_model="scrfd_500m_bnkps.onnx",
...     rec_model="arcface_r100_v1.onnx",
...     providers=["CPUExecutionProvider"],
... )
>>> frame = np.zeros((640, 640, 3), dtype=np.uint8)
>>> embeddings = pipeline(frame)  # doctest: +SKIP
"""

from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass, field
from typing import Any, Dict, Iterable, List, Mapping, Optional, Sequence, Tuple, TYPE_CHECKING, Union

from ._device import resolve_device_config
from .detectors import BoundingBox

if TYPE_CHECKING:  # pragma: no cover - imported for typing only
    import numpy as np

try:  # pragma: no cover - optional dependency guard
    import numpy as _np
except Exception:  # pragma: no cover - fallback when numpy is missing
    _np = None


LOGGER = logging.getLogger(__name__)


class FacePipelineError(RuntimeError):
    """Raised when the InsightFace pipeline fails."""


@dataclass
class FaceEmbedding:
    """A face detection enriched with an embedding vector."""

    bbox: BoundingBox
    keypoints: List[Tuple[float, float]]
    score: float
    embedding: Optional[List[float]] = None
    extras: Dict[str, Any] = field(default_factory=dict)


def _ensure_numpy() -> Any:
    if _np is None:
        raise FacePipelineError("numpy is required for face processing")
    return _np


def _as_image(image: Any) -> Any:
    np = _ensure_numpy()
    array = np.asarray(image)
    if array.ndim not in (2, 3):
        raise ValueError("InsightFace expects HxW or HxWxC arrays")
    return array


def _resolve_ctx_id(device: Optional[Union[str, int]], config: Mapping[str, Any]) -> int:
    if isinstance(device, int):
        return device
    if isinstance(device, str):
        lowered = device.lower()
        if lowered.startswith("cuda"):
            parts = lowered.split(":", 1)
            if len(parts) == 2 and parts[1].isdigit():
                return int(parts[1])
            return 0
        if lowered.startswith("gpu") and ":" in lowered:
            _, index = lowered.split(":", 1)
            if index.isdigit():
                return int(index)
        if lowered.startswith("cpu"):
            return -1
    candidate = config.get("ctx_id") or config.get("device") or config.get("gpu")
    if isinstance(candidate, int):
        return candidate
    if isinstance(candidate, str):
        lowered = candidate.lower()
        if lowered in {"cpu", "-1"}:
            return -1
        if lowered.isdigit():
            return int(lowered)
    provider = config.get("provider") or config.get("execution_provider")
    if isinstance(provider, str) and provider.lower().startswith("cpu"):
        return -1
    return -1


def _resolve_det_size(config: Mapping[str, Any], default: Tuple[int, int]) -> Tuple[int, int]:
    size = config.get("det_size") or config.get("image_size") or config.get("size")
    if isinstance(size, (list, tuple)) and len(size) == 2:
        return int(size[0]), int(size[1])
    if isinstance(size, int):
        return int(size), int(size)
    if isinstance(size, str) and "x" in size:
        left, right = size.lower().split("x", 1)
        if left.isdigit() and right.isdigit():
            return int(left), int(right)
    return default


def _normalise_providers(config: Mapping[str, Any], providers: Optional[Sequence[str]]) -> Optional[List[str]]:
    if providers:
        return [str(p) for p in providers]
    candidate = config.get("providers") or config.get("provider")
    if isinstance(candidate, str):
        return [candidate]
    if isinstance(candidate, Sequence):
        return [str(item) for item in candidate]
    return None


class InsightFacePipeline:
    """Run SCRFD detection followed by ArcFace embedding with retries."""

    def __init__(
        self,
        det_model: str,
        rec_model: str,
        *,
        device: Optional[Union[str, int]] = None,
        device_manager: Optional[Any] = None,
        providers: Optional[Sequence[str]] = None,
        model_root: Optional[str] = None,
        det_threshold: float = 0.5,
        nms_threshold: float = 0.4,
        align_size: int = 112,
        max_attempts: int = 3,
        timeout: Optional[float] = 10.0,
    ) -> None:
        self.det_model = det_model
        self.rec_model = rec_model
        general_config = resolve_device_config(device_manager, "insightface")
        detector_config = resolve_device_config(device_manager, "insightface.detector")
        merged_config: Dict[str, Any] = {**general_config, **detector_config}

        self.ctx_id = _resolve_ctx_id(device, merged_config)
        self.det_size = _resolve_det_size(merged_config, (640, 640))
        self.providers = _normalise_providers(merged_config, providers)
        self.model_root = model_root
        self.det_threshold = float(det_threshold)
        self.nms_threshold = float(nms_threshold)
        self.align_size = int(align_size)
        self.max_attempts = max(1, int(max_attempts))
        self.timeout = timeout

        self._detector = None
        self._embedder = None
        self._model_lock = threading.Lock()

    def _load_models(self) -> Tuple[Any, Any]:
        try:
            from insightface.model_zoo import get_model  # type: ignore
            from insightface.utils import face_align  # noqa: F401  # ensure dependency is present
        except Exception as exc:  # pragma: no cover - optional dependency
            raise FacePipelineError("insightface is required for face embeddings") from exc

        kwargs = {"download": False}
        if self.model_root is not None:
            kwargs["root"] = self.model_root
        if self.providers is not None:
            kwargs["providers"] = self.providers

        try:
            detector = get_model(self.det_model, **kwargs)
            embedder = get_model(self.rec_model, **kwargs)
        except Exception as exc:
            raise FacePipelineError("Unable to load InsightFace models") from exc

        try:
            detector.prepare(ctx_id=self.ctx_id, det_thresh=self.det_threshold, nms_thresh=self.nms_threshold)
        except Exception as exc:
            raise FacePipelineError("Failed to prepare SCRFD detector") from exc

        try:
            embedder.prepare(ctx_id=self.ctx_id)
        except Exception as exc:
            raise FacePipelineError("Failed to prepare ArcFace embedder") from exc

        return detector, embedder

    def _ensure_models(self) -> Tuple[Any, Any]:
        if self._detector is not None and self._embedder is not None:
            return self._detector, self._embedder

        with self._model_lock:
            if self._detector is None or self._embedder is None:
                self._detector, self._embedder = self._load_models()
        return self._detector, self._embedder

    @staticmethod
    def _convert_keypoints(points: Any) -> List[Tuple[float, float]]:
        np = _ensure_numpy()
        array = np.asarray(points, dtype=float)
        if array.ndim == 1:
            array = array.reshape(-1, 2)
        return [(float(x), float(y)) for x, y in array]

    @staticmethod
    def _compute_embedding(embedder: Any, aligned_face: Any) -> List[float]:
        vector = embedder.get(aligned_face)
        if hasattr(vector, "tolist"):
            return [float(v) for v in vector.tolist()]
        if isinstance(vector, Iterable):
            return [float(v) for v in vector]
        return [float(vector)]

    def _align_face(self, image: Any, keypoints: Any) -> Any:
        np = _ensure_numpy()
        try:
            from insightface.utils import face_align  # type: ignore
        except Exception as exc:  # pragma: no cover - optional dependency
            raise FacePipelineError("insightface.utils.face_align is required") from exc
        return face_align.norm_crop(image, keypoints, image_size=self.align_size)

    def _infer_once(self, image: Any, max_faces: Optional[int], with_embeddings: bool) -> List[FaceEmbedding]:
        detector, embedder = self._ensure_models()
        max_num = 0 if max_faces is None else int(max_faces)
        try:
            bboxes, keypoints = detector.detect(image, max_num=max_num)
        except Exception as exc:
            raise FacePipelineError("SCRFD detection failed") from exc

        np = _ensure_numpy()
        bboxes_array = np.asarray(bboxes) if bboxes is not None else np.zeros((0, 5))
        keypoints_array = np.asarray(keypoints) if keypoints is not None else np.zeros((0, 5, 2))

        results: List[FaceEmbedding] = []
        for idx in range(len(bboxes_array)):
            bbox_values = bboxes_array[idx]
            score = float(bbox_values[4]) if bbox_values.shape[0] >= 5 else 0.0
            bbox = BoundingBox(*[float(v) for v in bbox_values[:4]])
            kps = keypoints_array[idx] if idx < len(keypoints_array) else None
            keypoint_list = self._convert_keypoints(kps) if kps is not None else []

            embedding: Optional[List[float]] = None
            if with_embeddings and kps is not None:
                aligned = self._align_face(image, kps)
                embedding = self._compute_embedding(embedder, aligned)

            results.append(
                FaceEmbedding(
                    bbox=bbox,
                    keypoints=keypoint_list,
                    score=score,
                    embedding=embedding,
                )
            )
        return results

    def analyze(
        self,
        image: Any,
        *,
        max_faces: Optional[int] = None,
        with_embeddings: bool = True,
    ) -> List[FaceEmbedding]:
        """Detect faces and optionally compute embeddings with retry safety."""

        frame = _as_image(image)
        deadline = time.monotonic() + self.timeout if self.timeout is not None else None
        attempts = 0
        last_error: Optional[Exception] = None

        while attempts < self.max_attempts:
            attempts += 1
            try:
                return self._infer_once(frame, max_faces=max_faces, with_embeddings=with_embeddings)
            except Exception as exc:  # pragma: no cover - depends on runtime errors
                last_error = exc
                LOGGER.debug("InsightFace inference failed (attempt %s/%s)", attempts, self.max_attempts, exc_info=True)
                if deadline is not None and time.monotonic() >= deadline:
                    break
                if attempts >= self.max_attempts:
                    break
                time.sleep(min(0.5 * attempts, 1.5))

        raise FacePipelineError("InsightFace pipeline failed") from last_error

    def __call__(
        self,
        image: Any,
        *,
        max_faces: Optional[int] = None,
        with_embeddings: bool = True,
    ) -> List[FaceEmbedding]:
        return self.analyze(image, max_faces=max_faces, with_embeddings=with_embeddings)


__all__ = ["FaceEmbedding", "FacePipelineError", "InsightFacePipeline"]
