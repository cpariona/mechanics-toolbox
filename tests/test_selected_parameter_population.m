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
verifyEqual(testCase, ...
    population.initialShearModulus.values.InitialShearModulus, ...
    [12;15;18], "AbsTol", 1e-8);
end

function testGroupSummariesAreProduced(testCase)
batch = localBatch();
population = mechanics.workflow.summarizeSelectedParameters(batch);
verifyGreaterThan(testCase, height(population.overallSummary), 0);
verifyGreaterThan(testCase, height(population.groupSummary), 0);
verifyTrue(testCase, all(ismember(["A";"B"], unique(population.groupSummary.Group))));
end

function testInitialShearModulusModelFormulas(testCase)
parameterTable = table( ...
    ["neo";"mr";"mr";"yeoh";"yeoh";"yeoh"], ...
    repmat("all",6,1), ...
    ["neo-hookean";"mooney-rivlin";"mooney-rivlin"; ...
     "yeoh";"yeoh";"yeoh"], ...
    ["mu";"C10";"C01";"C10";"C20";"C30"], ...
    [10;3;2;4;7;9], ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter','Value'});

result = mechanics.statistics.deriveInitialShearModulus(parameterTable);
verifyEqual(testCase, result.values.SpecimenId, ["neo";"mr";"yeoh"]);
verifyEqual(testCase, result.values.InitialShearModulus, [10;10;8]);
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
axesHandles = findall(figureHandle, 'Type', 'axes', '-not', 'Tag', 'legend');
verifyEqual(testCase, numel(axesHandles), 3);
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

function testExportCreatesFiles(testCase)
batch = localBatch();
population = mechanics.workflow.summarizeSelectedParameters(batch);
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportSelectedParameterPopulation(population, folder);
verifyTrue(testCase, isfile(files.parameters));
verifyTrue(testCase, isfile(files.overall));
verifyTrue(testCase, isfile(files.groups));
verifyTrue(testCase, isfile(files.errors));
verifyTrue(testCase, isfile(files.initialShearValues));
verifyTrue(testCase, isfile(files.initialShearSummary));
verifyTrue(testCase, isfile(files.initialShearErrors));
verifyTrue(testCase, isfile(files.data));
end

function population = localMixedPopulation()
parameterTable = table( ...
    ["S1";"S2";"S2";"S3";"S3";"S3"], ...
    repmat("all",6,1), ...
    ["neo-hookean";"mooney-rivlin";"mooney-rivlin"; ...
     "yeoh";"yeoh";"yeoh"], ...
    ["mu";"C10";"C01";"C10";"C20";"C30"], ...
    [10;3;2;4;7;9], ...
    nan(6,1), nan(6,1), nan(6,1), ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter','Value', ...
    'BootstrapLower','BootstrapMedian','BootstrapUpper'});
population.parameterTable = parameterTable;
population.overallSummary = table( ...
    ["neo-hookean";"mooney-rivlin";"mooney-rivlin";"yeoh";"yeoh";"yeoh"], ...
    ["mu";"C10";"C01";"C10";"C20";"C30"], ...
    ones(6,1), [10;3;2;4;7;9], zeros(6,1), [10;3;2;4;7;9], ...
    [10;3;2;4;7;9], [10;3;2;4;7;9], zeros(6,1), true(6,1), ...
    'VariableNames', {'ModelName','Parameter','SpecimenCount','Mean', ...
    'StandardDeviation','Median','Minimum','Maximum', ...
    'CoefficientOfVariation','MeetsMinimumCount'});
population.specimenCount = 3;
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
workflow = config.comparisonConfig.fitDiagnosticsConfig;
workflow.runBootstrap = false;
workflow.runIdentifiability = false;
workflow.runWindowStability = false;
workflow.runResidualDiagnostics = false;
config.comparisonConfig.fitDiagnosticsConfig = workflow;
batch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, "neo-hookean", mechanics.config.fittingConfig(), config);
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder,'s');
end
end