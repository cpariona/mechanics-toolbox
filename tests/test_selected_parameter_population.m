function tests = test_selected_parameter_population
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testSelectedParametersAreExtracted(testCase)
population = mechanics.workflow.summarizeSelectedParameters(localBatch());
verifyEqual(testCase, population.specimenCount, 3);
verifyEqual(testCase, height(population.parameterTable), 3);
verifyTrue(testCase, all(population.parameterTable.Parameter == "mu"));
verifyEqual(testCase, height(population.extractionErrors), 0);
end

function testGroupSummariesAreProduced(testCase)
population = mechanics.workflow.summarizeSelectedParameters(localBatch());
verifyGreaterThan(testCase, height(population.overallSummary), 0);
verifyGreaterThan(testCase, height(population.groupSummary), 0);
verifyTrue(testCase, all(ismember(["A";"B"], unique(population.groupSummary.Group))));
end

function testExportCreatesFiles(testCase)
population = mechanics.workflow.summarizeSelectedParameters(localBatch());
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportSelectedParameterPopulation(population, folder);
verifyTrue(testCase, isfile(files.parameters));
verifyTrue(testCase, isfile(files.overall));
verifyTrue(testCase, isfile(files.groups));
verifyTrue(testCase, isfile(files.errors));
verifyTrue(testCase, isfile(files.data));
end

function batch = localBatch()
strain = linspace(0,0.5,51)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
parameters = [12,15,18];
groups = ["A","A","B"];
for index = 1:3
    specimens(index).specimenId = "S" + index; %#ok<AGROW>
    specimens(index).group = groups(index); %#ok<AGROW>
    specimens(index).deformation = strain; %#ok<AGROW>
    specimens(index).measuredStress = mechanics.models.evaluateModel("neo-hookean", strain, parameters(index), context); %#ok<AGROW>
    specimens(index).context = context; %#ok<AGROW>
end
config = mechanics.config.batchModelComparisonConfig();
workflow = config.comparisonConfig.fitDiagnosticsConfig;
workflow.runBootstrap = false;
workflow.runIdentifiability = false;
workflow.runWindowStability = false;
workflow.runResidualDiagnostics = false;
config.comparisonConfig.fitDiagnosticsConfig = workflow;
batch = mechanics.workflow.compareModelsAcrossSpecimens(specimens, "neo-hookean", mechanics.config.fittingConfig(), config);
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder,'s');
end
end
