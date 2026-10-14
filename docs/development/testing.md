# Testing

Initialize the repository before running focused tests:

```matlab
startup
```

`startup` adds the repository root and maintained subfolders to the MATLAB path. This allows individual test setup functions to resolve the root entrypoint even when the test runner temporarily changes the working directory.

Run the complete suite:

```matlab
results = run_all_tests();
```

The runner discovers every test under `tests/`, includes subfolders, prints a result table, and raises `mechanics:tests:RepositoryTestsFailed` when any test fails or remains incomplete.

## Test organization

Test files are grouped by subsystem or workflow rather than by implementation phase. Important boundaries include:

- low-level mechanics and constitutive models;
- import, extraction, and unit normalization;
- curve segmentation and quality assessment;
- fitting, diagnostics, uncertainty, and model selection;
- tensile and compression workflows;
- population and group analysis;
- plotting and presentation contracts;
- Markdown serialization, exports, and reports;
- end-to-end regression behavior.

`test_plotting_units.m` protects the stored-unit, display-unit, and mechanical-label boundary. It also verifies that label migration does not alter plotted data.

`test_markdown_table_serialization.m` protects the shared scalar Markdown contract, including numeric precision, non-finite values, missing text, logicals, datetime values, scalar cells, escaped pipes, and the retained blank line after a table.

Yeoh-family coverage is distributed by maintained behavior rather than by migration phase:

```text
test_constitutive_models.m
    second- and third-order Yeoh equations, explicit registered identities,
    family/order/display metadata, parameter counts, output shape,
    reference configuration, Neo-Hookean reduction, and rejection of bare yeoh

test_tensile_application_range_fitting.m
    shared second-order and third-order Yeoh fitting and explicit four-model fitting

test_tensile_application_range_selection.m
    registry-derived parameter count, mu0, and parsimony across Yeoh orders

test_joint_fixed_model_fitting.m
    second-order Yeoh recovery across independent tension and compression modes

test_joint_model_selection.m
    explicit second-order and third-order Yeoh joint selection

test_selected_parameter_population.m
    registry-derived mu0, consensus population, plotting, CSV, and MAT persistence

test_study_consensus_model.m
    canonical third-order identity through study-level consensus selection and export

test_tensile_application_range_workflow.m
    second-order Yeoh end-to-end workflow, report, figures, and MAT export

test_joint_material_characterization_workflow.m
    second-order Yeoh end-to-end joint workflow, report, figures, and MAT export
```

The user reported successful local MATLAB execution of all focused migration tests and the complete `run_all_tests()` suite after the final explicit-order identity migration. MATLAB was run locally by the user, not by the assistant.

Final real-study regeneration was also completed after the test gate. The maintained tensile, compression, tensile application-range, and joint-characterization drivers all ran successfully with explicit registered identities `yeoh-second-order` and `yeoh-third-order`. Review of the generated bundle confirmed canonical model identities in CSV outputs and unchanged scientific conclusions relative to the pre-rename four-candidate run.

Tests created only to verify a temporary migration or removed compatibility alias should be deleted once the canonical API is covered by functional tests. Test count alone is not a cleanup target; redundant behavior coverage, duplicated fixtures, and unnecessarily repeated expensive workflows are.

## Running focused tests

Calling a function-based test file by name constructs and displays its suite but does not execute the tests:

```matlab
test_joint_mode_plotting
```

A returned `Test` array is therefore not a pass or failure result.

Execute one test file with `runtests`:

```matlab
results = runtests( ...
    "tests/test_joint_mode_plotting.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

Execute several affected files together:

```matlab
results = runtests([ ...
    "tests/test_plotting_units.m"
    "tests/test_markdown_table_serialization.m"
    "tests/test_joint_mode_plotting.m"
    ], "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

List discovered tests without executing the complete suite:

```matlab
suite = testsuite("tests", "IncludeSubfolders", true);
disp(string({suite.Name})')
```

## Release validation

Before merging maintenance or release changes, run from the branch intended for merge:

```matlab
restoredefaultpath
clear classes
clear functions
clear
clc
close all

cd("<repository-folder>")
startup
results = run_all_tests();
assert(all([results.Passed]), "Repository tests failed.")
```

Shared Git review and delivery requirements follow the pinned engineering standard
referenced by root `AGENTS.md`. The mechanics-specific output hygiene check is:

```bash
git ls-files results
```

The mechanics release gate requires:
- every discovered MATLAB test to pass from the candidate branch;
- no incomplete MATLAB tests;
- no generated outputs tracked under `results/`;
- documentation consistent with any changed mechanics contracts.

Report the exact MATLAB execution status and unrun checks under the shared engineering standard.
