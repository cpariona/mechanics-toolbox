# mechanics-toolbox — agent instructions

Before modifying code, read the shared standard pinned at `.research-automation/standards/engineering.md`. If the private submodule is missing, stop and initialize it; do not substitute an informal copy or a moving `main` URL.

## Local contracts

- `src/+mechanics/` contains maintained implementation; `studies/` contains experimental drivers, `examples/` contains examples, and `tests/` contains tests. See [repository structure](docs/development/repository-structure.md) for ownership and APIs.
- Completed studies have one canonical result. Comparisons and joint characterization consume it without repeating raw-data import, segmentation, or fitting.
- `mechanics.models.modelRegistry` owns model identities, parameters, and derived quantities. `yeoh-second-order` and `yeoh-third-order` are distinct registered models; `yeoh` names only their family/evaluator and is not a compatible alias.
- Keep specimen, fitting, study, and report configuration contracts separate. Do not change the candidate-model defaults during non-scientific refactoring.
- Do not infer stored values or units from plot labels. `mechanics.io` owns report serialization and `mechanics.plotting` owns presentation-unit conversion.
- Experimental data and generated results under `data/` and `results/` must not be committed.
- Validate using `startup; results = run_all_tests();` and the maintained [testing protocol](docs/development/testing.md).
- Read [context handoff](docs/development/context-handoff.md) for open issues; Git/PRs own chronology.
