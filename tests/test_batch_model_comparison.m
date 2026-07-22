function tests = test_batch_model_comparison
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testBatchSelectsModelPerSpecimen(testCase)
specimens = localSpecimens();
config = localConfig();
batch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, ["neo-hookean", "mooney-rivlin"], ...
    mechanics.config.fittingConfig(), config);
verifyEqual(testCase, batch.specimenCount, 3);
verifyEqual(testCase, batch.successfulSpecimenCount, 3);
verifyEqual(testCase, batch.selectedSpecimenCount, 3);
verifyEqual(testCase, height(batch.specimenSummary), 3);
verifyGreaterThan(testCase, height(batch.modelSummary), 0);
end

function testGroupSummaryIsProduced(testCase)
specimens = localSpecimens();
config = localConfig();
batch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, "neo-hookean", mechanics.config.fittingConfig(), config);
verifyGreaterThan(testCase, height(batch.groupSummary), 0);
verifyTrue(testCase, all(ismember(["A";"B"], unique(batch.groupSummary.Group))));
end

function testExportCreatesFiles(testCase)
specimens = localSpecimens();
config = localConfig();
batch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, "neo-hookean", mechanics.config.fittingConfig(), config);
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportBatchModelComparison(batch, folder);
verifyTrue(testCase, isfile(files.specimens));
verifyTrue(testCase, isfile(files.models));
verifyTrue(testCase, isfile(files.groups));
verifyTrue(testCase, isfile(files.data));
end

function config = localConfig()
config = mechanics.config.batchModelComparisonConfig();
workflow = config.comparisonConfig.fitDiagnosticsConfig;
workflow.runBootstrap = false;
workflow.runIdentifiability = false;
workflow.runWindowStability = false;
workflow.runResidualDiagnostics = false;
config.comparisonConfig.fitDiagnosticsConfig = workflow;
end

function specimens = localSpecimens()
strain = linspace(0, 0.5, 51)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
parameters = [12, 15, 18];
groups = ["A", "A", "B"];
for index = 1:3
    specimens(index).specimenId = "S" + index; %#ok<AGROW>
    specimens(index).group = groups(index); %#ok<AGROW>
    specimens(index).deformation = strain; %#ok<AGROW>
    specimens(index).measuredStress = mechanics.models.evaluateModel( ...
        "neo-hookean", strain, parameters(index), context); %#ok<AGROW>
    specimens(index).context = context; %#ok<AGROW>
end
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end
