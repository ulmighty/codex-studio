"""Tests for EVP feature extraction utilities."""
from __future__ import annotations

import wave
from pathlib import Path

import pytest

from packages.audio.evp import extract_evp_features


@pytest.fixture(scope="module")
def generated_tone_path(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """Create a temporary sine wave recording for EVP feature tests."""

    pytest.importorskip("librosa")
    numpy = pytest.importorskip("numpy")

    sample_rate = 16_000
    duration_seconds = 1.0
    t = numpy.arange(int(sample_rate * duration_seconds)) / sample_rate
    waveform = 0.2 * numpy.sin(2 * numpy.pi * 440.0 * t)

    scaled = numpy.clip(waveform, -1.0, 1.0)
    int_samples = (scaled * 32767).astype("<i2")

    audio_dir = tmp_path_factory.mktemp("audio")
    file_path = audio_dir / "tone.wav"
    with wave.open(str(file_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(int_samples.tobytes())

    return file_path


def test_extract_evp_features_has_expected_structure(generated_tone_path: Path) -> None:
    result = extract_evp_features(generated_tone_path)

    assert result.sample_rate == 16_000
    assert result.duration > 0.5
    assert "mfcc_00_mean" in result.features
    assert not result.anomaly_flags.is_silent
    assert isinstance(result.anomaly_flags.high_noise, bool)
    assert result.disclaimer
