function config = residualDiagnosticsConfig()
%RESIDUALDIAGNOSTICSCONFIG Default constitutive-fit residual diagnostics.
config.standardizedResidualThreshold = 3.0;
config.autocorrelationThreshold = 0.50;
config.deformationCorrelationThreshold = 0.50;
config.heteroscedasticityCorrelationThreshold = 0.50;
config.minimumObservations = 8;
config.normalizationFloor = sqrt(eps);
end
