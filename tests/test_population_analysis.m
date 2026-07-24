function tests = test_population_analysis
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

function testMedianPopulationCurve(testCase)
strain = linspace(0, 1, 21)';
specimens(1) = localProcessedSpecimenFromData("one", strain, strain);
specimens(2) = localProcessedSpecimenFromData("two", strain, 2 .* strain);
specimens(3) = localProcessedSpecimenFromData("three", strain, 100 .* strain);
config = mechanics.config.populationAnalysisConfig();
config.centralStatistic = "median";
config.strainGridPointCount = 21;
config.bootstrap.enabled = false;
aggregate = mechanics.statistics.aggregateStressStrain(specimens, config);
verifyEqual(testCase, aggregate.centralStress, 2 .* strain, "AbsTol", 1e-12);
verifyEqual(testCase, aggregate.centralStatistic, "median");
verifyEqual(testCase, aggregate.meanStress, (103/3) .* strain, "AbsTol", 1e-12);
end

function testAggregateTangentModulus(testCase)
strain = linspace(0, 1, 21)';
specimens(1) = localProcessedSpecimenFromData("one", strain, 2 .* strain);
specimens(2) = localProcessedSpecimenFromData("two", strain, 4 .* strain);
specimens(1).analysis.tangentModulus = ...
    localTangentResult(strain, 2 .* ones(size(strain)));
specimens(2).analysis.tangentModulus = ...
    localTangentResult(strain, 4 .* ones(size(strain)));

config = mechanics.config.populationAnalysisConfig();
config.strainGridPointCount = 11;
config.bootstrap.enabled = false;

aggregate = mechanics.statistics.aggregateTangentModulus( ...
    specimens, config);

verifyEqual(testCase, aggregate.specimenCount, 2);
verifyEqual(testCase, aggregate.specimenCountByPoint, 2 .* ones(11, 1));
verifyEqual(testCase, aggregate.strain, linspace(0, 1, 11)');
verifyEqual(testCase, aggregate.centralModulus, 3 .* ones(11, 1), ...
    "AbsTol", 1e-12);
verifyEqual(testCase, aggregate.standardError, ones(11, 1), ...
    "AbsTol", 1e-12);
end

function testTangentModulusUsesPlotCurveAndMinimumSupport(testCase)
strain = linspace(0, 1, 11)';
specimens(1) = localProcessedSpecimenFromData("one", strain, strain);
specimens(2) = localProcessedSpecimenFromData("two", strain, strain);
specimens(3) = localProcessedSpecimenFromData("three", strain, strain);

modulusOne = 2 .* ones(size(strain));
modulusOne(1:3) = NaN;
modulusTwo = 4 .* ones(size(strain));
modulusTwo(1:2) = NaN;
modulusThree = 8 .* ones(size(strain));
modulusThree(1:6) = NaN;

specimens(1).analysis.tangentModulus = ...
    localTangentResult(strain, modulusOne);
specimens(2).analysis.tangentModulus = ...
    localTangentResult(strain, modulusTwo);
specimens(3).analysis.tangentModulus = ...
    localTangentResult(strain, modulusThree);

config = mechanics.config.populationAnalysisConfig();
config.minimumSpecimens = 2;
config.strainGridPointCount = 9;
config.bootstrap.enabled = false;

aggregate = mechanics.statistics.aggregateTangentModulus( ...
    specimens, config);

verifyEqual(testCase, aggregate.strainRange, [0.2, 1], ...
    "AbsTol", 1e-12);
verifyEqual(testCase, aggregate.specimenCountByPoint(1), 2);
verifyEqual(testCase, aggregate.centralModulus(1), 3, "AbsTol", 1e-12);
verifyEqual(testCase, aggregate.specimenCountByPoint(end), 3);
verifyEqual(testCase, aggregate.centralModulus(end), 14/3, ...
    "AbsTol", 1e-12);
end

function testTangentModulusMedianBootstrapIsDeterministic(testCase)
strain = linspace(0, 1, 11)';
values = [2, 4, 20];
for index = 1:numel(values)
    specimens(index) = localProcessedSpecimenFromData( ...
        "specimen-" + index, strain, strain); %#ok<AGROW>
    specimens(index).analysis.tangentModulus = ...
        localTangentResult(strain, values(index) .* ones(size(strain))); %#ok<AGROW>
end

config = mechanics.config.populationAnalysisConfig();
config.centralStatistic = "median";
config.strainGridPointCount = 5;
config.bootstrap.iterations = 100;
config.bootstrap.randomSeed = 7;

first = mechanics.statistics.aggregateTangentModulus(specimens, config);
second = mechanics.statistics.aggregateTangentModulus(specimens, config);

verifyEqual(testCase, first.centralModulus, 4 .* ones(5, 1));
verifyEqual(testCase, first.confidenceLower, second.confidenceLower);
verifyEqual(testCase, first.confidenceUpper, second.confidenceUpper);
end

function testTangentModulusExplicitRangeRequiresSupport(testCase)
strain = linspace(0, 1, 11)';
specimens(1) = localProcessedSpecimenFromData("one", strain, strain);
specimens(2) = localProcessedSpecimenFromData("two", strain, strain);
modulusOne = ones(size(strain));
modulusOne(1:3) = NaN;
modulusTwo = 2 .* ones(size(strain));
modulusTwo(1:2) = NaN;
specimens(1).analysis.tangentModulus = ...
    localTangentResult(strain, modulusOne);
specimens(2).analysis.tangentModulus = ...
    localTangentResult(strain, modulusTwo);

config = mechanics.config.populationAnalysisConfig();
config.strainRangeMode = "explicit";
config.explicitStrainRange = [0.1, 0.9];
config.bootstrap.enabled = false;

verifyError(testCase, ...
    @() mechanics.statistics.aggregateTangentModulus(specimens, config), ...
    "mechanics:statistics:TangentModulusRangeOutsideSupport");
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
verifyEqual(testCase, population.tangentModulus.centralModulus, ...
    3 .* ones(21, 1), "AbsTol", 1e-12);
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
cleanup = onCleanup(@() localRemoveFolder(folder)); %#ok<NASGU>

population.curves.strain = [0; 1];
population.curves.meanStress = [0; 2];
population.curves.standardDeviation = [0; 0.1];
population.curves.standardError = [0; 0.05];
population.curves.confidenceLower = [0; 1.8];
population.curves.confidenceUpper = [0; 2.2];
population.tangentModulus.strain = [0; 1];
population.tangentModulus.meanModulus = [1; 2];
population.tangentModulus.medianModulus = [1; 2];
population.tangentModulus.centralModulus = [1; 2];
population.tangentModulus.centralStatistic = "mean";
population.tangentModulus.standardDeviation = [0.1; 0.2];
population.tangentModulus.standardError = [0.05; 0.1];
population.tangentModulus.confidenceLower = [0.8; 1.8];
population.tangentModulus.confidenceUpper = [1.2; 2.2];
population.tangentModulus.specimenCountByPoint = [2; 2];
population.metrics = table("MaximumStress", 2, ...
    'VariableNames', {'Metric', 'SampleCount'});
population.modelParameters.values = table();
population.modelParameters.summary = table();

files = mechanics.io.exportPopulationAnalysis( ...
    population, folder);

verifyTrue(testCase, isfile(files.curve));
verifyTrue(testCase, isfile(files.tangentModulus));
verifyTrue(testCase, isfile(files.metrics));
verifyTrue(testCase, isfile(files.population));
end

function specimen = localProcessedSpecimen(id, slope)
strain = linspace(0, 1, 21)';
specimen = localProcessedSpecimenFromData(id, strain, slope .* strain);
end

function specimen = localProcessedSpecimenFromData(id, strain, stress)
specimen.id = string(id);
specimen.processed.strain = strain;
specimen.processed.stress = stress;
specimen.analysis.tangentModulus = ...
    localTangentResult(strain, gradient(stress, strain));
end

function tangent = localTangentResult(strain, modulusForPlot)
tangent.strain = strain(:);
tangent.tangentModulus = modulusForPlot(:);
tangent.tangentModulusForPlot = modulusForPlot(:);
tangent.summaryStrainRange = [min(strain), max(strain)];
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
