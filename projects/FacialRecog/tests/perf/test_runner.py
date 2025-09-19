from __future__ import annotations

from projects.FacialRecog.packages.perf.runner import BenchmarkKnobs, BenchmarkRunner


def test_runner_returns_results():
    knobs = BenchmarkKnobs(batch_sizes=[1, 2], image_sizes=[512], model_variants=["base"])
    runner = BenchmarkRunner(knobs, iterations=1, work_factor=60.0)
    results = runner.run()
    assert len(results) == 2
    for result in results:
        assert result.duration > 0
        assert result.throughput > 0
        assert result.stage_durations is None


def test_runner_profile_collects_stage_timings():
    knobs = BenchmarkKnobs(batch_sizes=[1], image_sizes=[512], model_variants=["large"])
    runner = BenchmarkRunner(knobs, iterations=2, work_factor=60.0)
    results = runner.run(profile=True)
    assert len(results) == 1
    stages = results[0].stage_durations
    assert stages is not None
    assert set(stages) == {"preprocess", "inference", "postprocess"}
    assert all(value > 0 for value in stages.values())


def test_runner_validates_iterations():
    knobs = BenchmarkKnobs(batch_sizes=[1], image_sizes=[512], model_variants=["base"])
    try:
        BenchmarkRunner(knobs, iterations=0)
    except ValueError:
        pass
    else:  # pragma: no cover - defensive guard
        raise AssertionError("Expected ValueError for zero iterations")


def test_runner_validates_knobs():
    knobs = BenchmarkKnobs(batch_sizes=[], image_sizes=[512], model_variants=["base"])
    try:
        BenchmarkRunner(knobs)
    except ValueError:
        pass
    else:  # pragma: no cover - defensive guard
        raise AssertionError("Expected ValueError for empty knob list")
