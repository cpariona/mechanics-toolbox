# Compression study

The compression workflow imports force-displacement data, discards configured conditioning cycles, selects the maintained test cycle and analysis branch, and runs the shared uniaxial processing pipeline.

## Configuration hierarchy

- `compressionConfig` controls preprocessing and mechanics for one processed compression curve;
- `compressionStudyConfig` coordinates import, cycle selection, geometry, fitting, export, and reporting for one specimen;
- `compressionPopulationConfig` and `runCompressionPopulationStudy` remain transitional and are scheduled for replacement by completed-study comparison;
- `compressionStudyReportConfig` controls report figures and Markdown rendering only.

```matlab
config = mechanics.config.compressionStudyConfig();
config.geometry.initialLength = 25;
config.geometry.initialArea = 100;
study = mechanics.workflow.runCompressionStudy("compression.csv", config);
```

## Conditioning and branch selection

Compression files may contain repeated conditioning cycles before the maintained measurement cycle. Cycle selection must exclude those cycles from specimen mechanics and constitutive fitting.

```matlab
config.cycle.selection = "last-complete-cycle";
config.cycle.branch = "loading";
config.cycle.loadingDirection = "increasing";
```

Only the selected branch is passed to tangent-modulus estimation and optional constitutive fitting. The complete selected cycle may be retained as raw provenance, but conditioning cycles are not part of the analyzed mechanical response.

## Sign contract

Instrument signs and stored mechanical signs are separate concerns. The maintained internal state uses physical signs:

```text
tension:     displacement > 0, strain > 0, stress > 0, stretch > 1
compression: displacement < 0, strain < 0, stress < 0, 0 < stretch < 1
```

Compression peak force, peak displacement, and other report-oriented cycle quantities may remain positive magnitudes. Those presentation values do not alter `study.specimen.processed`.

This contract ensures that engineering strain, true strain, stretch, area evolution, true stress, tangent modulus, constitutive fitting, and measurement Monte Carlo all use one consistent mechanical representation.

## Constitutive fitting

The same incompressible uniaxial models used in tension can be fitted directly to the stored compression state:

```matlab
config.fitting.enabled = true;
config.fitting.modelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
```

No post-processing sign inversion is required before fitting. Measurement Monte Carlo refitting uses the same processed specimen state.

## Area units

Measured area can be normalized automatically to mm2:

```matlab
config.import.currentAreaUnit = "cm2";
config.import.normalizeCurrentAreaUnits = true;
```

Supported units include `um2`, `mm2`, `cm2`, `m2`, and `in2` with common textual variants.

## Population migration

The maintained direction is to process each compression dataset first and compare completed compression studies through a dedicated workflow analogous to `compareTensileStudies`.

`runCompressionPopulationStudy` should not be extended. Its manifest processing, group comparison, export, and plotting responsibilities must be separated before it is removed. The replacement must reuse common population and group-analysis contracts rather than duplicate them under compression-specific names.

## Validation

Real compression datasets require visual confirmation of:

- exclusion of conditioning cycles;
- selected measurement cycle and loading branch;
- contact or zero-reference handling;
- physical sign normalization;
- fitting range and area assumptions.
