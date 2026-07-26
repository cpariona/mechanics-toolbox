function tests = test_compression_population
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testCompressionNeoHookeanFitting(testCase)
filename = localCompressionFile(2.5, 25, 10);
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
config = mechanics.config.compressionSpecimenConfig();
config.geometry.initialLength = 25;
config.geometry.initialArea = 10;
config.cycle.smoothingFrameLength = 1;
config.processing.analysis.summaryStrainRange = [-0.15, 0];
config.fitting.enabled = true;
config.fitting.modelNames = "neo-hookean";
config.fitting.selectionConfig.windowFractions = 1;
config.fitting.selectionConfig.minimumObservations = 12;
config.fitting.selectionConfig.requireConvergence = false;
config.fitting.selectionConfig.maximumRelativeParameterCV = Inf;
study = mechanics.workflow.runCompressionSpecimen(filename, config);

processed = study.specimen.processed;
verifyLessThanOrEqual(testCase, max(processed.force), 0);
verifyLessThanOrEqual(testCase, max(processed.displacement), 0);
verifyLessThanOrEqual(testCase, max(processed.strain), 0);
verifyLessThanOrEqual(testCase, max(processed.stress), 0);
verifyGreaterThan(testCase, min(processed.stretch), 0);
verifyLessThanOrEqual(testCase, max(processed.stretch), 1);
verifyGreaterThanOrEqual(testCase, min(processed.areaScale), 1);
verifyGreaterThanOrEqual(testCase, study.cycleMetrics.peakForce, 0);
verifyGreaterThanOrEqual(testCase, study.cycleMetrics.peakDisplacement, 0);

verifyTrue(testCase, study.specimen.modelSelection.selection.hasEligibleModel);
verifyEqual(testCase, ...
    study.specimen.modelSelection.selection.bestModel, "neo-hookean");
record = study.specimen.modelSelection.records( ...
    [study.specimen.modelSelection.records.succeeded]);
verifyEqual(testCase, record(end).fitResult.parameters(1), 2.5, ...
    "RelTol", 0.05);
end

function testCompletedCompressionStudiesAreCompared(testCase)
files = strings(4, 1);
cleanup = onCleanup(@() localDeleteMany(files)); %#ok<NASGU>
for index = 1:4
    files(index) = localCompressionFile(2 + 0.5 .* index, 25, 10);
end

firstManifest = table(files(1:2), ["A1";"A2"], repmat(10, 2, 1), ...
    'VariableNames', {'File','SpecimenId','InitialArea'});
secondManifest = table(files(3:4), ["B1";"B2"], repmat(10, 2, 1), ...
    'VariableNames', {'File','SpecimenId','InitialArea'});

studyConfig = mechanics.config.compressionStudyConfig();
studyConfig.specimen.cycle.smoothingFrameLength = 1;
studyConfig.specimen.processing.analysis.summaryStrainRange = [-0.15, 0];
studyConfig.population.config.bootstrap.enabled = false;
studyConfig.population.config.strainGridPointCount = 21;

first = mechanics.workflow.runCompressionStudy(firstManifest, studyConfig);
second = mechanics.workflow.runCompressionStudy(secondManifest, studyConfig);
verifyEqual(testCase, first.manifest.InitialLength, repmat(25, 2, 1));
verifyEqual(testCase, string({first.analysis.records.status})', ...
    repmat("processed", 2, 1));
verifyEqual(testCase, first.populationStatus, "completed");
verifyEqual(testCase, second.populationStatus, "completed");

comparisonConfig = mechanics.config.compressionStudyComparisonConfig();
comparisonConfig.groupComparison.minimumSpecimensPerGroup = 2;
comparisonConfig.groupComparison.populationConfig.minimumSpecimens = 2;
comparisonConfig.groupComparison.populationConfig.bootstrap.enabled = false;
comparisonConfig.groupComparison.populationConfig.strainGridPointCount = 21;
comparisonConfig.groupComparison.bootstrap.enabled = false;
comparisonConfig.groupComparison.export.enabled = false;
comparison = mechanics.workflow.compareCompressionStudies( ...
    [first, second], ["A", "B"], comparisonConfig);

verifyEqual(testCase, comparison.testType, "compression");
verifyEqual(testCase, comparison.studySummaries.ProcessedCount, [2; 2]);
verifyEqual(testCase, comparison.groupComparison.groups(1).specimenCount, 2);
verifyEqual(testCase, comparison.groupComparison.groups(2).specimenCount, 2);
verifyGreaterThan(testCase, height(comparison.groupComparison.metricComparison), 0);
verifyTrue(testCase, comparison.compatibility.measuresMatch);
verifyTrue(testCase, comparison.compatibility.unitsMatch);
end

function filename = localCompressionFile(mu, initialLength, initialArea)
loadingDisplacement = linspace(0, 5, 31)';
compressionStrain = loadingDisplacement ./ initialLength;
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
nominalStress = mechanics.models.evaluateModel( ...
    "neo-hookean", -compressionStrain, mu, context);
loadingForce = -nominalStress .* initialArea;
unloadingDisplacement = linspace(5, 0, 31)';
unloadingForce = flipud(loadingForce);
displacement = [loadingDisplacement; unloadingDisplacement(2:end)];
force = [loadingForce; unloadingForce(2:end)];
filename = string(tempname) + ".csv";
writetable(table(force, displacement, ...
    'VariableNames', {'Force','Displacement'}), filename);
end

function localDelete(filename)
if isfile(filename)
    delete(filename);
end
end

function localDeleteMany(files)
for index = 1:numel(files)
    if strlength(files(index)) > 0 && isfile(files(index))
        delete(files(index));
    end
end
end
