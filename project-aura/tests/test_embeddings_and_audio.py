import numpy as np

from aura.features.c1_ai_voice_enhancement import extract_spectral_features
from aura.features.c3_biometric_security import compute_face_embedding
from aura.utils.faiss_stub import search_index


def test_face_embedding_shape_and_norm():
    rng = np.random.default_rng(42)
    image = rng.integers(0, 255, size=(32, 32), dtype=np.uint8)
    embedding = compute_face_embedding(image)
    assert embedding.shape == (128,)
    # Embeddings are L2 normalised which makes downstream similarity search
    # deterministic.
    assert np.isclose(np.linalg.norm(embedding), 1.0, atol=1e-6)


def test_faiss_style_search_returns_indices():
    rng = np.random.default_rng(7)
    index = rng.normal(size=(5, 4)).astype(np.float32)
    queries = np.stack([index[2] + 0.01, index[4] + 0.01]).astype(np.float32)
    distances, indices = search_index(index, queries, k=2)
    assert indices.shape == (2, 2)
    assert distances.shape == (2, 2)
    # Each query should identify itself as the nearest neighbour.
    assert indices[0, 0] == 2
    assert indices[1, 0] == 4


def test_audio_feature_extraction_non_empty():
    sample_rate = 16_000
    duration = 0.1
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False, dtype=np.float32)
    audio = np.sin(2 * np.pi * 440 * t).astype(np.float32)
    features = extract_spectral_features(audio, sample_rate=sample_rate)
    assert features.size > 0
    # Features are normalised to [0, 1].  Max should be 1 for a simple sine wave.
    assert np.isclose(features.max(), 1.0, atol=1e-6)
