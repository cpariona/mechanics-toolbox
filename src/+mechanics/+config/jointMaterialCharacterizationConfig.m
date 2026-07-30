function config = jointMaterialCharacterizationConfig()
%JOINTMATERIALCHARACTERIZATIONCONFIG Configure joint material characterization.
config.candidateModelNames = ["neo-hookean"; "mooney-rivlin"; "yeoh"];
config.modeNames = ["tension"; "compression"];
config.modeWeights = [1; 1];
config.specimenWeighting = "equal";
config.normalization.method = "response-range";
config.normalization.minimumScale = sqrt(eps);
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