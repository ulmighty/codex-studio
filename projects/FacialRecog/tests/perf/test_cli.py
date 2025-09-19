from __future__ import annotations

from projects.FacialRecog.packages.perf import cli


def test_cli_dry_run(capsys):
    argv = [
        "--batch-sizes",
        "1",
        "--image-sizes",
        "512",
        "--models",
        "base",
        "--dry-run",
    ]
    exit_code = cli.main(argv)
    assert exit_code == 0
    output = capsys.readouterr().out
    assert "Planning 1 benchmark scenario" in output
    assert "batch=1 image=512px model=base" in output


def test_cli_profile_output(capsys):
    argv = [
        "--batch-sizes",
        "1",
        "--image-sizes",
        "512",
        "--models",
        "base",
        "--iterations",
        "1",
        "--profile",
    ]
    exit_code = cli.main(argv)
    assert exit_code == 0
    output = capsys.readouterr().out
    assert "Executed 1 scenario" in output
    assert "preprocess" in output
    assert "inference" in output
    assert "postprocess" in output
