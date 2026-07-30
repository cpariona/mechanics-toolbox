function config = jointCharacterizationAuditConfig()
%JOINTCHARACTERIZATIONAUDITCONFIG Configure one-factor robustness audits.
config.modeWeightSets = [1, 1; 3, 1; 1, 3];
config.samplingFractions = [1; 0.5];
config.deformationFractions = [1; 0.75];
config.specimensPerMode = [Inf; 1];
config.minimumObservationsPerSpecimen = 3;
end
