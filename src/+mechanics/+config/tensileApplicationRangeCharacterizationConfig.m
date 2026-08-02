function config = tensileApplicationRangeCharacterizationConfig()
%TENSILEAPPLICATIONRANGECHARACTERIZATIONCONFIG Configure range-limited tension analysis.
config.deformationMeasure = "engineering-strain";
config.fitRange = [0, 0.30];
config.minimumObservationsPerSpecimen = 10;
config.minimumSpecimens = 2;
config.requireRangeMaximum = false;
config.candidateModelNames = ["neo-hookean"; "mooney-rivlin"; "yeoh"];
config.requireFiniteObservations = true;
config.requireMatchingStressUnits = true;
config.requireMatchingStrainUnits = true;
config.signTolerance.deformationRelative = 1e-8;
config.signTolerance.stressRelative = 1e-3;
config.signTolerance.absolute = 100 * eps;
end
