function config = studyConsensusModelConfig()
%STUDYCONSENSUSMODELCONFIG Configure study-level constitutive consensus.
config.minimumSuccessfulFraction = 0.75;
config.minimumEligibleFraction = 0.75;
config.bicTieTolerance = 2.0;
config.requireFiniteParameters = true;
config.bootstrap.enabled = true;
config.bootstrap.iterations = 2000;
config.bootstrap.confidenceLevel = 0.95;
config.bootstrap.randomSeed = 1;
end
