function config = tensileApplicationRangeCharacterizationConfig()
%TENSILEAPPLICATIONRANGECHARACTERIZATIONCONFIG Configure range-limited tension analysis.
config.deformationMeasure = "engineering-strain";
config.fitRange = [0, 0.50];
config.minimumObservationsPerSpecimen = 10;
config.minimumSpecimens = 2;
config.requireRangeMaximum = false;
config.candidateModelNames = ["neo-hookean"; "mooney-rivlin"; "yeoh"];
config.specimenWeighting = "equal";
config.normalization.method = "response-range";
config.normalization.minimumScale = sqrt(eps);
config.fitting = mechanics.config.fittingConfig();
config.selection.requireConvergence = true;
config.selection.practicalObjectiveTolerance = 0.02;
config.selection.tieBreakOrder = config.candidateModelNames;
config.rangeSensitivity.maximumDeformations = [0.30; 0.40; 0.50];
config.compressionValidation.minimumSpecimens = 1;
config.export.enabled = false;
config.export.outputFolder = "results/tensile-application-range-characterization";
config.requireFiniteObservations = true;
config.requireMatchingStressUnits = true;
config.requireMatchingStrainUnits = true;
config.signTolerance.deformationRelative = 1e-8;
config.signTolerance.stressRelative = 1e-3;
config.signTolerance.absolute = 100 * eps;
end
