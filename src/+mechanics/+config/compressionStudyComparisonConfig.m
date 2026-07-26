function config = compressionStudyComparisonConfig()
%COMPRESSIONSTUDYCOMPARISONCONFIG Configure completed study comparison.
config.requireMatchingMeasures = true;
config.requireMatchingUnits = true;
config.groupComparison = mechanics.config.groupComparisonConfig();
end
