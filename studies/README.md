# Study drivers

This directory contains executable configurations for real experimental studies.

Study drivers are not library implementation and are not simplified examples:

- reusable implementation belongs under `src/+mechanics/`;
- short demonstrations belong under `examples/`;
- automated verification belongs under `tests/`;
- experiment-specific executable configuration belongs under `studies/`.

A study driver may define input paths, specimen exclusions, measurement assumptions, fitting settings, optional analyses, output folders, and report configuration. It should call maintained public APIs rather than reproduce implementation logic.

Use one subdirectory per test family or experimental campaign. Keep raw data and generated results outside version control under `data/` and `results/`.

Current driver:

```text
studies/tension/run_tensile_experiment.m
```
