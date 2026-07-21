# Tensile curve segmentation

Phase 11 separates monotonic loading from post-fracture unloading.

The default method ends the analysis region at the first global maximum of
finite force. The complete acquisition remains in `specimen.raw`; the selected
pre-fracture region is stored in `specimen.analysisRaw`.

Processing order:

```text
raw curve -> segmentation -> quality assessment -> stress-strain -> fitting
```

Default configuration:

```matlab
config.segmentation.enabled = true;
config.segmentation.method = "pre-peak";
config.segmentation.analysisPeakFraction = 1.0;
config.segmentation.minimumPostPeakDropFraction = 0.20;
```

`analysisPeakFraction = 0.98` may be used later to exclude the immediate
pre-peak damage region, but the default remains 1.0 until that criterion is
experimentally validated.

Fracture detection is descriptive and does not reject a specimen.
