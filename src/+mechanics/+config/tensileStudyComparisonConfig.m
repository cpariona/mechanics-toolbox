function config = tensileStudyComparisonConfig()
%TENSILESTUDYCOMPARISONCONFIG Configure comparison of completed tensile studies.
config.requireMatchingMeasures = true;
config.requireMatchingUnits = true;
config.groupComparison = mechanics.config.groupComparisonConfig();
end
