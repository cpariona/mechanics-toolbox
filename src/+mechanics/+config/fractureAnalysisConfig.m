function config = fractureAnalysisConfig()
%FRACTUREANALYSISCONFIG Default configuration for tensile fracture metrics.
config.enabled = true;
config.completeFractureDropFraction = 0.90;
config.residualForceFraction = 0.10;
config.integrateAbsoluteDisplacement = false;
config.minimumObservations = 3;
end
