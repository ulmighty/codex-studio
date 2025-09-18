"""Synthetic benchmark runner for FaceTrace components."""
from __future__ import annotations

from dataclasses import dataclass
from itertools import product
import math
import time
from typing import Dict, List, Mapping, Sequence


@dataclass(frozen=True)
class BenchmarkScenario:
    """A single combination of knobs to benchmark."""

    batch_size: int
    image_size: int
    model_variant: str


@dataclass(frozen=True)
class BenchmarkKnobs:
    """Input knobs controlling the benchmark search space."""

    batch_sizes: Sequence[int]
    image_sizes: Sequence[int]
    model_variants: Sequence[str]


@dataclass(frozen=True)
class BenchmarkResult:
    """Collected metrics for a benchmark scenario."""

    scenario: BenchmarkScenario
    duration: float
    throughput: float
    stage_durations: Mapping[str, float] | None = None


class BenchmarkRunner:
    """Execute synthetic benchmarks for different configuration knobs."""

    _MODEL_WEIGHTS: Mapping[str, float] = {
        "nano": 0.35,
        "micro": 0.45,
        "tiny": 0.6,
        "small": 0.75,
        "base": 1.0,
        "medium": 1.2,
        "large": 1.6,
        "xl": 2.1,
    }

    _STAGE_MULTIPLIERS: Mapping[str, float] = {
        "preprocess": 0.4,
        "inference": 1.3,
        "postprocess": 0.35,
    }

    def __init__(
        self,
        knobs: BenchmarkKnobs,
        *,
        iterations: int = 3,
        work_factor: float = 120.0,
    ) -> None:
        if iterations <= 0:
            raise ValueError("iterations must be positive")
        if not knobs.batch_sizes or not knobs.image_sizes or not knobs.model_variants:
            raise ValueError("All knob collections must contain at least one value")

        self.knobs = knobs
        self.iterations = iterations
        self.work_factor = work_factor
        self._scenarios: List[BenchmarkScenario] = [
            BenchmarkScenario(batch, image, model)
            for batch, image, model in product(
                knobs.batch_sizes, knobs.image_sizes, knobs.model_variants
            )
        ]

    @property
    def scenarios(self) -> Sequence[BenchmarkScenario]:
        """Return the generated benchmark scenarios."""

        return tuple(self._scenarios)

    def run(self, *, profile: bool = False) -> List[BenchmarkResult]:
        """Execute benchmarks and return collected metrics."""

        results: List[BenchmarkResult] = []
        for scenario in self._scenarios:
            stage_totals: Dict[str, float] | None = (
                {name: 0.0 for name in self._STAGE_MULTIPLIERS}
                if profile
                else None
            )
            start = time.perf_counter()
            for _ in range(self.iterations):
                if profile:
                    iteration_profile = self._run_profiled_iteration(scenario)
                    for stage, elapsed in iteration_profile.items():
                        assert stage_totals is not None  # for type checkers
                        stage_totals[stage] += elapsed
                else:
                    self._run_iteration(scenario)
            total_duration = time.perf_counter() - start
            if stage_totals is not None:
                stage_durations = {
                    stage: elapsed / self.iterations for stage, elapsed in stage_totals.items()
                }
            else:
                stage_durations = None
            throughput = self._compute_throughput(scenario, total_duration)
            results.append(
                BenchmarkResult(
                    scenario=scenario,
                    duration=total_duration,
                    throughput=throughput,
                    stage_durations=stage_durations,
                )
            )
        return results

    def _compute_throughput(self, scenario: BenchmarkScenario, duration: float) -> float:
        if duration <= 0:
            return float("inf")
        return (scenario.batch_size * self.iterations) / duration

    def _run_iteration(self, scenario: BenchmarkScenario) -> None:
        complexity = self._complexity_factor(scenario)
        for stage, multiplier in self._STAGE_MULTIPLIERS.items():
            self._simulate_stage(complexity, multiplier, stage)

    def _run_profiled_iteration(self, scenario: BenchmarkScenario) -> Mapping[str, float]:
        timings: Dict[str, float] = {}
        complexity = self._complexity_factor(scenario)
        for stage, multiplier in self._STAGE_MULTIPLIERS.items():
            start = time.perf_counter()
            self._simulate_stage(complexity, multiplier, stage)
            timings[stage] = time.perf_counter() - start
        return timings

    def _complexity_factor(self, scenario: BenchmarkScenario) -> float:
        pixel_factor = max(1.0, scenario.image_size / 512.0)
        batch_factor = max(1.0, math.sqrt(scenario.batch_size))
        variant_factor = self._MODEL_WEIGHTS.get(
            scenario.model_variant.lower(), 1.0 + 0.05 * len(scenario.model_variant)
        )
        return pixel_factor * batch_factor * variant_factor

    def _simulate_stage(self, complexity: float, multiplier: float, stage: str) -> None:
        work_units = max(120, int(self.work_factor * complexity * multiplier))
        acc = 0
        modulo = 97 + len(stage)
        for i in range(work_units):
            acc += (i * 17) % modulo
        # Prevent optimisation removing the loop
        if acc == -1:  # pragma: no cover - never triggered
            raise RuntimeError("unexpected sentinel value")
