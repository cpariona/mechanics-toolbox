function config = peakAnalysisConfig()
%PEAKANALYSISCONFIG Default configuration for tensile peak metrics.
config.enabled = true;
config.integrateAbsoluteDisplacement = false;
config.minimumObservations = 3;
end
