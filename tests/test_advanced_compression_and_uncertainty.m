function tests = test_advanced_compression_and_uncertainty
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testAreaUnitsNormalizeToSquareMillimetres(testCase)
[area, unit, conversion] = mechanics.io.normalizeAreaUnits([1; 2], "cm^2");
verifyEqual(testCase, area, [100; 200], "AbsTol", 1e-12);
verifyEqual(testCase, unit, "mm2");
verifyEqual(testCase, conversion.factor, 100);
end

function testCompressionNeoHookeanFitting(testCase)
filename = localCompressionFile(2.5, 25, 10);
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
config = mechanics.config.compressionStudyConfig();
config.geometry.initialLength = 25;
config.geometry.initialArea = 10;
config.cycle.smoothingFrameLength = 1;
config.processing.analysis.summaryStrainRange = [0, 0.15];
config.fitting.enabled = true;
config.fitting.modelNames = "neo-hookean";
config.fitting.selectionConfig.windowFractions = 1;
config.fitting.selectionConfig.minimumObservations = 12;
config.fitting.selectionConfig.requireConvergence = false;
config.fitting.selectionConfig.maximumRelativeParameterCV = Inf;
study = mechanics.workflow.runCompressionStudy(filename, config);
verifyTrue(testCase, study.specimen.modelSelection.selection.hasEligibleModel);
verifyEqual(testCase, study.specimen.modelSelection.selection.bestModel, "neo-hookean");
record = study.specimen.modelSelection.records([study.specimen.modelSelection.records.succeeded]);
verifyEqual(testCase, record(end).fitResult.parameters(1), 2.5, "RelTol", 0.05);
end

function testGeometryMonteCarloRefitsParameters(testCase)
strain = linspace(0, 0.25, 41)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
stress = mechanics.models.evaluateModel("neo-hookean", strain, 3, context);
fit = mechanics.fitting.fitModel("neo-hookean", strain, stress, context, ...
    mechanics.config.fittingConfig());
specimen.geometry.initialLength = 25;
specimen.geometry.initialArea = 10;
specimen.processed.displacement = strain .* 25;
specimen.processed.force = stress .* 10;
specimen.processed.strain = strain;
specimen.processed.stress = stress;
specimen.processingConfig = mechanics.config.tensionConfig();
config = mechanics.config.geometryMonteCarloFitConfig();
config.sampleCount = 20;
config.initialLengthStd = 0.1;
config.initialAreaStd = 0.1;
config.refitNumberOfStarts = 1;
result = mechanics.fitting.geometryMonteCarloFitUncertainty( ...
    specimen, fit, config);
verifyGreaterThanOrEqual(testCase, result.successfulFraction, 0.8);
verifySize(testCase, result.parameterSamples, [20, 1]);
verifyLessThan(testCase, result.parameterLower(1), result.parameterUpper(1));
end

function testCompressionPopulationUsesDefaultLength(testCase)
files = strings(4,1);
cleanup = onCleanup(@() localDeleteMany(files)); %#ok<NASGU>
for index = 1:4
    files(index) = localCompressionFile(2 + 0.1 .* index, 25, 10);
end
manifest = table(files, ["A1";"A2";"B1";"B2"], ...
    ["A";"A";"B";"B"], repmat(10,4,1), ...
    'VariableNames', {'File','SpecimenId','Group','InitialArea'});
config = mechanics.config.compressionPopulationConfig();
config.studyConfig.cycle.smoothingFrameLength = 1;
config.studyConfig.processing.analysis.summaryStrainRange = [0, 0.15];
config.population.bootstrap.enabled = false;
result = mechanics.workflow.runCompressionPopulationStudy(manifest, config);
verifyEqual(testCase, result.manifest.InitialLength, repmat(25,4,1));
verifyEqual(testCase, string({result.records.status})', repmat("processed",4,1));
verifyEqual(testCase, string({result.groups.status})', ["processed";"processed"]);
verifyEqual(testCase, [result.groups.specimenCount]', [2;2]);
end

function filename = localCompressionFile(mu, initialLength, initialArea)
loadingDisplacement = linspace(0, 5, 31)';
compressionStrain = loadingDisplacement ./ initialLength;
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
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
