# Geometry uncertainty propagation

The uniaxial workflow can propagate standard uncertainty in the initial gauge length and initial cross-sectional area to the reported strain and stress curves.

The feature is disabled by default:

```matlab
config = mechanics.config.tensionConfig();
config.uncertainty.geometry.enabled = false;
```

Enable it by providing standard uncertainties in the same units as the geometry:

```matlab
config.uncertainty.geometry.enabled = true;
config.uncertainty.geometry.initialLengthStd = 0.10; % mm
config.uncertainty.geometry.initialAreaStd = 0.20;   % mm^2
```

For the end-to-end tensile workflow, use:

```matlab
config = mechanics.config.tensileStudyConfig();
config.datasetAnalysis.processingConfig.uncertainty.geometry.enabled = true;
config.datasetAnalysis.processingConfig.uncertainty.geometry.initialLengthStd = 0.10;
config.datasetAnalysis.processingConfig.uncertainty.geometry.initialAreaStd = 0.20;
```

## Method

The implementation uses first-order uncertainty propagation. Numerical central differences estimate the sensitivity of the configured stress and strain measures to `initialLength` and `initialArea`; independent contributions are then combined in quadrature.

This supports engineering and true measures, including the configured area-evolution model. It does not currently propagate force, displacement, preload-threshold, smoothing, or constitutive-fitting uncertainty.

## Results

When enabled, the processed specimen contains:

```text
specimen.analysis.geometryUncertainty.strainStandardUncertainty
specimen.analysis.geometryUncertainty.stressStandardUncertainty
specimen.analysis.geometryUncertainty.strainRelativeStandardUncertainty
specimen.analysis.geometryUncertainty.stressRelativeStandardUncertainty
```

The exported specimen curve CSV adds the same four quantities as columns.

## Interpretation

The values are standard uncertainties, not 95% confidence intervals. A coverage interval requires an explicitly chosen coverage factor or a probabilistic model. Geometry uncertainty should remain separate from between-specimen biological or manufacturing variability.
