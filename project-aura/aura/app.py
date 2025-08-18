from __future__ import annotations

from typing import Callable, Dict

from .core import config as config_module
from .core.command_bus import CommandBus
from .providers.appaware.win32_foreground import Win32ForegroundProvider
from .providers.bodytracking.kinect_v2 import KinectV2Provider
from .providers.gaze.kinect_headpose import KinectHeadPoseProvider
from .providers.input.win_mousekbd import WinMouseKeyboardProvider
from .providers.llm.openai_gpt import OpenAIGPTProvider
from .providers.noise.rnnoise_local import RNNoiseLocal
from .providers.virtualcam.pyvirtualcam_obs import PyVirtualCamOBS
from .providers.voice.whisper_local import WhisperLocalProvider
from .providers.wakeword.porcupine import PorcupineProvider

ProviderFactory = Callable[[], object]


def _null_factory() -> object:
    return object()


PROVIDER_MAP: Dict[str, ProviderFactory] = {
    "kinect_v2": KinectV2Provider,
    "whisper_local": WhisperLocalProvider,
    "porcupine": PorcupineProvider,
    "rnnoise_local": RNNoiseLocal,
    "pyvirtualcam_obs": PyVirtualCamOBS,
    "mediapipe_task": _null_factory,
    "kinect_headpose": KinectHeadPoseProvider,
    "win32_foreground": Win32ForegroundProvider,
    "win_mousekbd": WinMouseKeyboardProvider,
}


class AuraApp:
    """Lightweight orchestrator for wiring providers together."""

    def __init__(self) -> None:
        self.config = config_module.load_config()
        self.bus = CommandBus()
        self.providers: Dict[str, object] = {}

    def setup_providers(self) -> None:
        names = self.config.providers
        self.providers["bodytracking"] = PROVIDER_MAP[names.bodytracking]()
        self.providers["voice"] = PROVIDER_MAP[names.voice]()
        self.providers["wakeword"] = PROVIDER_MAP[names.wakeword]()
        self.providers["noise"] = PROVIDER_MAP[names.noise]()
        self.providers["virtualcam"] = PROVIDER_MAP[names.virtualcam]()
        self.providers["gaze"] = PROVIDER_MAP[names.gaze]()
        self.providers["appaware"] = PROVIDER_MAP[names.appaware]()
        self.providers["input"] = PROVIDER_MAP[names.input]()
        self.providers["llm"] = OpenAIGPTProvider(self.config.llm.model)

    def run(self) -> None:  # pragma: no cover - orchestration
        self.setup_providers()
        print("Aura app initialised with providers:", list(self.providers))
