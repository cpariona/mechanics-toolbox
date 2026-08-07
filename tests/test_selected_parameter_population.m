function tests = test_selected_parameter_population
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testSelectedParametersAreExtracted(testCase)
batch = localBatch();
population = mechanics.workflow.summarizeSelectedParameters(batch);
verifyEqual(testCase, population.specimenCount, 3);
verifyEqual(testCase, height(population.parameterTable), 3);
verifyTrue(testCase, all(population.parameterTable.Parameter == "mu"));
verifyEqual(testCase, height(population.extractionErrors), 0);
verifyEqual(testCase, population.consensusModelName, "neo-hookean");
verifyEqual(testCase, population.selectionBasis, "consensus-model-refit");
verifyEqual(testCase, ...
    population.initialShearModulus.values.InitialShearModulus, ...
    [12;15;18], "AbsTol", 1e-8);
end

function testSecondOrderYeohConsensusFlowsThroughPopulation(testCase)
batch = localSecondOrderYeohBatch();
population = mechanics.workflow.summarizeSelectedParameters(batch);
verifyEqual(testCase, population.consensusModelName, "yeoh-second-order");
verifyEqual(testCase, population.specimenCount, 3);
verifyEqual(testCase, unique(population.parameterTable.ModelName), ...
    "yeoh-second-order");
verifyEqual(testCase, unique(population.parameterTable.Parameter, "stable"), ...
    ["C10"; "C20"]);
verifyEqual(testCase, ...
    population.initialShearModulus.values.InitialShearModulus, ...
    [0.10; 0.12; 0.14], "RelTol", 2e-3);
verifyEqual(testCase, height(population.initialShearModulus.errors), 0);
end

function testGroupSummariesAreProduced(testCase)
batch = localBatch();
population = mechanics.workflow.summarizeSelectedParameters(batch);
verifyGreaterThan(testCase, height(population.overallSummary), 0);
verifyGreaterThan(testCase, height(population.groupSummary), 0);
verifyTrue(testCase, all(ismember(["A";"B"], unique(population.groupSummary.Group))));
end

function testSingletonSummaryKeepsLocationAndOmitsDispersion(testCase)
batch = localBatch();
population = mechanics.workflow.summarizeSelectedParameters(batch);
row = population.groupSummary(population.groupSummary.Group == "B", :);
verifyEqual(testCase, row.SpecimenCount, 1);
verifyEqual(testCase, row.Mean, 18, "AbsTol", 1e-8);
verifyEqual(testCase, row.Median, 18, "AbsTol", 1e-8);
verifyEqual(testCase, row.Minimum, 18, "AbsTol", 1e-8);
verifyEqual(testCase, row.Maximum, 18, "AbsTol", 1e-8);
verifyTrue(testCase, isnan(row.StandardDeviation));
verifyTrue(testCase, isnan(row.CoefficientOfVariation));
verifyFalse(testCase, row.MeetsMinimumCount);
end

function testSingletonInitialShearSummaryOmitsDispersion(testCase)
parameterTable = table("sample", "all", "neo-hookean", "mu", 10, ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter','Value'});
result = mechanics.statistics.deriveInitialShearModulus(parameterTable);
verifyEqual(testCase, result.summary.SpecimenCount, 1);
verifyEqual(testCase, result.summary.Mean, 10);
verifyEqual(testCase, result.summary.Median, 10);
verifyEqual(testCase, result.summary.Minimum, 10);
verifyEqual(testCase, result.summary.Maximum, 10);
verifyTrue(testCase, isnan(result.summary.StandardDeviation));
verifyFalse(testCase, result.summary.MeetsMinimumCount);
end

function testInitialShearModulusModelFormulas(testCase)
parameterTable = table( ...
    ["neo";"mr";"mr";"yeoh2";"yeoh2";"yeoh";"yeoh";"yeoh"], ...
    repmat("all",8,1), ...
    ["neo-hookean";"mooney-rivlin";"mooney-rivlin"; ...
     "yeoh-second-order";"yeoh-second-order"; ...
     "yeoh";"yeoh";"yeoh"], ...
    ["mu";"C10";"C01";"C10";"C20";"C10";"C20";"C30"], ...
    [10;3;2;5;7;4;7;9], ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter','Value'});

result = mechanics.statistics.deriveInitialShearModulus(parameterTable);
verifyEqual(testCase, result.values.SpecimenId, ["neo";"mr";"yeoh2";"yeoh"]);
verifyEqual(testCase, result.values.ModelName, ...
    ["neo-hookean";"mooney-rivlin";"yeoh-second-order";"yeoh"]);
verifyEqual(testCase, result.values.InitialShearModulus, [10;10;10;8]);
verifyEqual(testCase, result.summary.Median, 10);
verifyEqual(testCase, height(result.errors), 0);
end

function testUnsupportedInitialShearModelIsRecorded(testCase)
parameterTable = table("sample", "all", "unknown-model", "p", 1, ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter','Value'});
result = mechanics.statistics.deriveInitialShearModulus(parameterTable);
verifyEqual(testCase, height(result.values), 0);
verifyEqual(testCase, result.errors.ErrorIdentifier, ...
    "mechanics:statistics:UnsupportedInitialShearModel");
end

function testParameterPlotSeparatesModelParameterCombinations(testCase)
population = localMixedPopulation();
figureHandle = mechanics.plotting.plotSelectedParameterPopulation(population);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
expectedKeys = [ ...
    "neo-hookean::mu"; ...
    "mooney-rivlin::C10"; ...
    "mooney-rivlin::C01"; ...
    "yeoh-second-order::C10"; ...
    "yeoh-second-order::C20"; ...
    "yeoh::C10"; ...
    "yeoh::C20"; ...
    "yeoh::C30"];
verifyEqual(testCase, figureHandle.UserData.parameterKeys, expectedKeys);
verifyTrue(testCase, isgraphics(figureHandle));
end

function testInitialShearModulusPlot(testCase)
population = localMixedPopulation();
figureHandle = mechanics.plotting.plotInitialShearModulusPopulation(population);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
verifyTrue(testCase, isgraphics(figureHandle));
axesHandles = findall(figureHandle, 'Type', 'axes', '-not', 'Tag', 'legend');
verifyEqual(testCase, numel(axesHandles), 1);
end

function testBatchComparisonDefaultsAreLightweight(testCase)
config = mechanics.config.batchModelComparisonConfig();
diagnostics = config.comparisonConfig.fitDiagnosticsConfig;
verifyFalse(testCase, diagnostics.runBootstrap);
verifyFalse(testCase, diagnostics.runIdentifiability);
verifyFalse(testCase, diagnostics.runWindowStability);
verifyFalse(testCase, diagnostics.runResidualDiagnostics);
end

function testExportCreatesOnlyRelevantFiles(testCase)
batch = localBatch();
population = mechanics.workflow.summarizeSelectedParameters(batch);
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportSelectedParameterPopulation(population, folder);
verifyTrue(testCase, isfile(files.selection));
verifyTrue(testCase, isfile(files.parameters));
verifyTrue(testCase, isfile(files.overall));
verifyTrue(testCase, isfile(files.groups));
verifyFalse(testCase, isfield(files, "errors"));
verifyTrue(testCase, isfile(files.initialShearValues));
verifyTrue(testCase, isfile(files.initialShearSummary));
verifyFalse(testCase, isfield(files, "initialShearErrors"));
verifyTrue(testCase, isfile(files.parameterFigure));
verifyTrue(testCase, isfile(fullfile(folder, "consensus_model_parameters.fig")));
verifyTrue(testCase, isfile(files.initialShearFigure));
verifyTrue(testCase, isfile(fullfile(folder, "consensus_initial_shear_modulus.fig")));
verifyTrue(testCase, isfile(files.data));
end

function population = localMixedPopulation()
parameterTable = table( ...
    ["S1";"S2";"S2";"S3";"S3";"S4";"S4";"S4"], ...
    repmat("all",8,1), ...
    ["neo-hookean";"mooney-rivlin";"mooney-rivlin"; ...
    "yeoh-second-order";"yeoh-second-order"; ...
    "yeoh";"yeoh";"yeoh"], ...
    ["mu";"C10";"C01";"C10";"C20";"C10";"C20";"C30"], ...
    [10;3;2;5;7;4;7;9], ...
    nan(8,1), nan(8,1), nan(8,1), ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter','Value', ...
    'BootstrapLower','BootstrapMedian','BootstrapUpper'});
population.parameterTable = parameterTable;
population.overallSummary = table( ...
    ["neo-hookean";"mooney-rivlin";"mooney-rivlin"; ...
     "yeoh-second-order";"yeoh-second-order";"yeoh";"yeoh";"yeoh"], ...
    ["mu";"C10";"C01";"C10";"C20";"C10";"C20";"C30"], ...
    ones(8,1), [10;3;2;5;7;4;7;9], nan(8,1), [10;3;2;5;7;4;7;9], ...
    [10;3;2;5;7;4;7;9], [10;3;2;5;7;4;7;9], nan(8,1), false(8,1), ...
    'VariableNames', {'ModelName','Parameter','SpecimenCount','Mean', ...
    'StandardDeviation','Median','Minimum','Maximum', ...
    'CoefficientOfVariation','MeetsMinimumCount'});
population.specimenCount = 4;
population.initialShearModulus = ...
    mechanics.statistics.deriveInitialShearModulus(parameterTable);
end

function batch = localBatch()
strain = linspace(0,0.5,51)';
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
parameters = [12,15,18];
groups = ["A","A","B"];
for index = 1:3
    specimens(index).specimenId = "S" + index; %#ok<AGROW>
    specimens(index).group = groups(index); %#ok<AGROW>
    specimens(index).deformation = strain; %#ok<AGROW>
    specimens(index).measuredStress = mechanics.models.evaluateModel( ...
        "neo-hookean", strain, parameters(index), context); %#ok<AGROW>
    specimens(index).context = context; %#ok<AGROW>
end
config = mechanics.config.batchModelComparisonConfig();
batch = mechanics.workflow.fitConsensusModelAcrossSpecimens( ...
    specimens, repmat("neo-hookean", 3, 1), ...
    ["neo-hookean";"mooney-rivlin"], ...
    mechanics.config.fittingConfig(), config);
end

function batch = localSecondOrderYeohBatch()
strain = linspace(0,0.5,61)';
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
parameters = [0.05, 0.01; 0.06, 0.012; 0.07, 0.014];
groups = ["A","A","B"];
for index = 1:3
    specimens(index).specimenId = "Y" + index; %#ok<AGROW>
    specimens(index).group = groups(index); %#ok<AGROW>
    specimens(index).deformation = strain; %#ok<AGROW>
    specimens(index).measuredStress = mechanics.models.evaluateModel( ...
        "yeoh-second-order", strain, parameters(index,:), context); %#ok<AGROW>
    specimens(index).context = context; %#ok<AGROW>
end
fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 10;
fitConfig.randomSeed = 9;
config = mechanics.config.batchModelComparisonConfig();
batch = mechanics.workflow.fitConsensusModelAcrossSpecimens( ...
    specimens, repmat("yeoh-second-order", 3, 1), ...
    ["neo-hookean";"yeoh-second-order";"yeoh"], ...
    fitConfig, config);
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder,'s');
end
end
