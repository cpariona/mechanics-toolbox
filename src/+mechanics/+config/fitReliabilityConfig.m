function config = fitReliabilityConfig()
%FITRELIABILITYCONFIG Default integrated constitutive-fit assessment.
config.maximumAcceptableNormalizedRmse = 0.10;
config.minimumAcceptableRSquared = 0.95;
config.minimumBootstrapSuccessFraction = 0.80;
config.reliableMaximumFlagCount = 0;
config.cautionMaximumFlagCount = 2;
config.requireAllDiagnostics = false;
end
