function config = curveSegmentationConfig()
%CURVESEGMENTATIONCONFIG Default configuration for tensile-curve segmentation.
config.enabled = true;
config.method = "pre-peak";
config.analysisPeakFraction = 1.0;

% Structural minimum required to identify a nontrivial curve segment.
% Specimen acceptance remains the responsibility of the quality layer.
config.minimumObservations = 2;
config.postPeakWindow = Inf;
end