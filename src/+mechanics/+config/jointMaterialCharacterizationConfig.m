function config = jointMaterialCharacterizationConfig()
%JOINTMATERIALCHARACTERIZATIONCONFIG Configure joint material characterization.
config.candidateModelNames = ["neo-hookean"; "mooney-rivlin"; "yeoh-third-order"];
config.modeNames = ["tension"; "compression"];
config.modeWeights = [1; 1];
config.specimenWeighting = "equal";
config.normalization.method = "response-range";
config.normalization.minimumScale = sqrt(eps);
config.signTolerance.deformationRelative = 1e-8;
config.signTolerance.stressRelative = 1e-3;
config.signTolerance.absolute = 100 * eps;
config.requireFiniteObservations = true;
config.requireMatchingStressUnits = true;
config.requireMatchingStrainUnits = true;
config.fitting = mechanics.config.fittingConfig();
config.selection.requireConvergence = true;
config.selection.practicalObjectiveTolerance = 0.02;
config.selection.tieBreakOrder = config.candidateModelNames;
config.export.enabled = false;
config.export.outputFolder = "results/joint-material-characterization";
end
