function tests = test_phase9_population_analysis
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testAggregateStressStrain(testCase)
specimens = [ ...
    localProcessedSpecimen("one", 2), ...
    localProcessedSpecimen("two", 4)];

config = mechanics.config.populationAnalysisConfig();
config.strainGridPointCount = 11;
config.bootstrap.enabled = false;

aggregate = mechanics.statistics.aggregateStressStrain( ...
    specimens, config);

verifyEqual(testCase, aggregate.specimenCount, 2);
verifyEqual(testCase, aggregate.strain, linspace(0, 1, 11)');
verifyEqual(testCase, aggregate.meanStress, ...
    3 .* aggregate.strain, "AbsTol", 1e-12);
verifyEqual(testCase, aggregate.standardError(end), 1);
end

function testBootstrapMeanInterval(testCase)
config.enabled = true;
config.iterations = 200;
config.confidenceLevel = 0.95;
config.randomSeed = 3;

result = mechanics.statistics.bootstrapMeanConfidenceInterval( ...
    [1, 2, 3, 4], config);

verifyEqual(testCase, result.mean, 2.5, "AbsTol", 1e-12);
verifyLessThanOrEqual(testCase, result.lower, result.mean);
verifyGreaterThanOrEqual(testCase, result.upper, result.mean);
end

function testPopulationMetricSummary(testCase)
summary = table( ...
    ["processed"; "processed"; "failed"], ...
    [1; 2; NaN], ...
    [10; 20; NaN], ...
    [100; 200; NaN], ...
    'VariableNames', { ...
        'Status', 'MaximumStrain', 'MaximumStress', ...
        'MedianTangentModulus'});

config = mechanics.config.populationAnalysisConfig();
config.bootstrap.enabled = false;

result = mechanics.statistics.summarizePopulationMetrics( ...
    summary, config);

maximumStress = result(result.Metric == "MaximumStress", :);
verifyEqual(testCase, maximumStress.SampleCount, 2);
verifyEqual(testCase, maximumStress.Mean, 15);
verifyEqual(testCase, maximumStress.StandardDeviation, ...
    sqrt(50), "AbsTol", 1e-12);
end

function testPopulationWorkflow(testCase)
analysis.records = [ ...
    localRecord("one", 2), ...
    localRecord("two", 4)];
analysis.summary = table( ...
    ["one"; "two"], ...
    ["processed"; "processed"], ...
    [1; 1], ...
    [2; 4], ...
    [2; 4], ...
    'VariableNames', { ...
        'SpecimenId', 'Status', 'MaximumStrain', ...
        'MaximumStress', 'MedianTangentModulus'});

config = mechanics.config.populationAnalysisConfig();
config.strainGridPointCount = 21;
config.bootstrap.enabled = false;

population = mechanics.workflow.analyzeSpecimenPopulation( ...
    analysis, config);

verifyEqual(testCase, population.specimenCount, 2);
verifyEqual(testCase, population.curves.meanStress(end), 3);
verifyEqual(testCase, height(population.metrics), 3);
end

function testInsufficientSpecimensRejected(testCase)
analysis.records = localRecord("one", 2);
analysis.summary = table( ...
    "one", "processed", 1, 2, 2, ...
    'VariableNames', { ...
        'SpecimenId', 'Status', 'MaximumStrain', ...
        'MaximumStress', 'MedianTangentModulus'});

verifyError(testCase, ...
    @() mechanics.workflow.analyzeSpecimenPopulation( ...
        analysis, mechanics.config.populationAnalysisConfig()), ...
    "mechanics:workflow:InsufficientProcessedSpecimens");
end

function testPopulationExport(testCase)
folder = string(tempname);
cleanup = onCleanup(@() localRemoveFolder(folder));

population.curves.strain = [0; 1];
population.curves.meanStress = [0; 2];
population.curves.standardDeviation = [0; 0.1];
population.curves.standardError = [0; 0.05];
population.curves.confidenceLower = [0; 1.8];
population.curves.confidenceUpper = [0; 2.2];
population.metrics = table("MaximumStress", 2, ...
    'VariableNames', {'Metric', 'SampleCount'});
population.modelParameters.values = table();
population.modelParameters.summary = table();

files = mechanics.io.exportPopulationAnalysis( ...
    population, folder);

verifyTrue(testCase, isfile(files.curve));
verifyTrue(testCase, isfile(files.metrics));
verifyTrue(testCase, isfile(files.population));
end

function specimen = localProcessedSpecimen(id, slope)
strain = linspace(0, 1, 21)';

specimen.id = string(id);
specimen.processed.strain = strain;
specimen.processed.stress = slope .* strain;
end

function record = localRecord(id, slope)
record.index = 1;
record.specimenId = string(id);
record.sheetName = string(id);
record.status = "processed";
record.quality = struct();
record.specimen = localProcessedSpecimen(id, slope);
record.errorIdentifier = "";
record.errorMessage = "";
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
