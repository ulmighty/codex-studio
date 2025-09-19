"""Command line interface for FaceTrace performance benchmarks."""
from __future__ import annotations

import argparse
from typing import Sequence

from .runner import BenchmarkKnobs, BenchmarkRunner


def positive_int(value: str) -> int:
    """Parse and validate positive integers for CLI arguments."""

    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("value must be a positive integer")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Synthetic FaceTrace benchmark runner",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--batch-sizes",
        type=positive_int,
        nargs="+",
        default=[1, 2, 4],
        metavar="BATCH",
        help="Batch sizes to evaluate",
    )
    parser.add_argument(
        "--image-sizes",
        type=positive_int,
        nargs="+",
        default=[512, 768],
        metavar="PX",
        help="Square image sizes (pixels)",
    )
    parser.add_argument(
        "--models",
        nargs="+",
        default=["base", "large"],
        metavar="NAME",
        help="Model variants to profile",
    )
    parser.add_argument(
        "--iterations",
        type=positive_int,
        default=3,
        help="Number of iterations to average per scenario",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print the planned benchmark scenarios without executing",
    )
    parser.add_argument(
        "--profile",
        action="store_true",
        help="Collect stage-level timings for each iteration",
    )
    return parser


def format_scenario(batch: int, image: int, model: str) -> str:
    return f"batch={batch} image={image}px model={model}"


def _print_dry_run(scenarios: Sequence) -> None:
    lines = [
        f"- {format_scenario(scenario.batch_size, scenario.image_size, scenario.model_variant)}"
        for scenario in scenarios
    ]
    output = [
        f"Planning {len(scenarios)} benchmark scenario(s):",
        *lines,
    ]
    for line in output:
        print(line)


def _print_results(results, profile: bool) -> None:
    if not results:
        print("No benchmarks executed; check CLI arguments.")
        return

    print(f"Executed {len(results)} scenario(s).")
    for result in results:
        scenario = result.scenario
        print(
            f"[{scenario.model_variant}] batch={scenario.batch_size} "
            f"image={scenario.image_size}px -> {result.throughput:.2f} samples/s "
            f"({result.duration:.4f}s total)"
        )
        if profile and result.stage_durations:
            for stage, elapsed in result.stage_durations.items():
                print(f"    {stage:>12}: {elapsed:.4f}s")


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    knobs = BenchmarkKnobs(
        batch_sizes=args.batch_sizes,
        image_sizes=args.image_sizes,
        model_variants=args.models,
    )
    runner = BenchmarkRunner(knobs, iterations=args.iterations)

    if args.dry_run:
        _print_dry_run(runner.scenarios)
        return 0

    results = runner.run(profile=args.profile)
    _print_results(results, profile=args.profile)
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    raise SystemExit(main())
