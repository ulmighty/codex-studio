# Hardware Presets

These presets provide reliable starting points for running FaceTrace's
synthetic benchmarks on popular workstation GPUs. They can be combined with
the CLI options exposed by `python -m perf`.

## GeForce RTX 3080 Ti (12 GB)

| Setting      | Recommended Value | Rationale |
|--------------|-------------------|-----------|
| Batch size   | 8                 | Keeps memory utilisation under ~11 GB while maintaining solid throughput. |
| Image size   | 768 px            | Balances detail with memory usage for models tuned to 1K inputs. |
| Model variant| `large`           | Highest tier that consistently fits without paging on 12 GB cards. |

Run with profiling enabled:

```bash
python -m perf --batch-sizes 8 --image-sizes 768 --models large --profile
```

## GeForce RTX 4080 Super (16 GB)

| Setting      | Recommended Value | Rationale |
|--------------|-------------------|-----------|
| Batch size   | 12                | Utilises the additional memory for higher throughput. |
| Image size   | 960 px            | Takes advantage of the larger cache and memory bandwidth for more detailed inputs. |
| Model variant| `xl`              | Premium model fits comfortably within the 16 GB frame buffer. |

Suggested command:

```bash
python -m perf --batch-sizes 12 --image-sizes 960 --models xl --profile
```

> Tip: add `--dry-run` to inspect the combinations without executing and
> `--iterations` to extend profiling runs once a stable configuration is found.
