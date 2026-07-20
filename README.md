# mechanics-toolbox

MATLAB toolbox for reproducible processing and constitutive analysis of mechanical-test data.

## Current scope

- preserve raw force-displacement data;
- preprocess experimental curves;
- compute uniaxial stress and strain;
- estimate tangent modulus;
- plot processed stress-strain curves;
- evaluate incompressible uniaxial hyperelastic models.

Numerical parameter fitting is intentionally not included yet.

## Setup

Run from the repository root:

```matlab
startup
```

## Mechanical processing

```matlab
config = mechanics.config.tensionConfig();
curve = mechanics.preprocessing.prepareCurve(rawCurve, config.preprocessing);
curve = mechanics.analysis.computeUniaxialMeasures(curve, geometry, config.mechanics);
result = mechanics.analysis.computeTangentModulus(curve, config.analysis);
mechanics.plotting.plotStressStrain(curve);
```

## Hyperelastic models

```matlab
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

stress = mechanics.models.evaluateModel( ...
    "neo-hookean", strain, mu, context);
```

Registered models:

- `neo-hookean`;
- `mooney-rivlin`;
- `yeoh`.

See `docs/hyperelastic_models.md` for equations and conventions.

## Validation

```matlab
startup
results = runtests("tests", "IncludeSubfolders", true);
disp(table(results))
assert(all([results.Passed]), "One or more tests failed.")
```

Examples:

```matlab
run_synthetic_tension_analysis
run_hyperelastic_models
```

## Architecture rule

Input/output, preprocessing, mechanics, constitutive models, plotting, statistics, and future fitting routines remain separate. Model functions only evaluate constitutive equations and do not read files, modify experimental data, plot, or invoke optimizers.
