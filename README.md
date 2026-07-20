# mechanics-toolbox — Phase 1

Stable MATLAB architecture for mechanical-test data processing.

## Install into an existing clone

Copy the contents of this package into the repository root, preserving folders. Existing root-level MATLAB files may remain temporarily as legacy references, but new code must use the package API under `src/+mechanics`.

## MATLAB validation

```matlab
startup
results = runtests("tests", "IncludeSubfolders", true);
disp(table(results))
assert(all([results.Passed]), "One or more tests failed.")
run_synthetic_tension_analysis
```

## Main API

```matlab
config = mechanics.config.tensionConfig();
curve = mechanics.preprocessing.prepareCurve(rawCurve, config.preprocessing);
curve = mechanics.analysis.computeUniaxialMeasures(curve, geometry, config.mechanics);
result = mechanics.analysis.computeTangentModulus(curve, config.analysis);
mechanics.plotting.plotStressStrain(curve);
```
