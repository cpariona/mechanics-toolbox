function tests = test_population_model_selection
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testUnanimousSelectionIsRecordedWithoutRefit(testCase)
analysis = localAnalysis(["yeoh-third-order";"yeoh-third-order";"yeoh-third-order"]);
config = localConfig();
population = mechanics.workflow.analyzeSpecimenPopulation(analysis, config);

selection = population.modelSelection;
verifyTrue(testCase, selection.hasConsensusModel);
verifyEqual(testCase, selection.consensusModelName, "yeoh-third-order");
verifyEqual(testCase, selection.consensusSelectionCount, 3);
verifyEqual(testCase, selection.consensusSelectionFraction, 1);
verifyTrue(testCase, selection.unanimous);
verifyEqual(testCase, height(selection.values), 3);
verifyEqual(testCase, selection.summary.SelectionCount, [0;0;3]);
end

function testUniqueMajorityIsDescriptiveConsensus(testCase)
analysis = localAnalysis(["yeoh-third-order";"yeoh-third-order";"mooney-rivlin"]);
config = localConfig();
population = mechanics.workflow.analyzeSpecimenPopulation(analysis, config);

selection = population.modelSelection;
verifyTrue(testCase, selection.hasConsensusModel);
verifyEqual(testCase, selection.consensusModelName, "yeoh-third-order");
verifyEqual(testCase, selection.consensusSelectionCount, 2);
verifyEqual(testCase, selection.consensusSelectionFraction, 2/3, "AbsTol", 1e-12);
verifyFalse(testCase, selection.unanimous);
verifyTrue(testCase, contains(selection.reason, "no population refit"));
end

function testTiedSelectionsHaveNoConsensus(testCase)
analysis = localAnalysis(["mooney-rivlin";"yeoh-third-order"]);
config = localConfig();
population = mechanics.workflow.analyzeSpecimenPopulation(analysis, config);

selection = population.modelSelection;
verifyFalse(testCase, selection.hasConsensusModel);
verifyEqual(testCase, selection.consensusModelName, "");
verifyTrue(testCase, contains(selection.reason, "tied"));
end

function testReportSectionExplainsUnanimousReuse(testCase)
analysis = localAnalysis(["yeoh-third-order";"yeoh-third-order"]);
population = mechanics.workflow.analyzeSpecimenPopulation(analysis, localConfig());
filename = string(tempname) + ".md";
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
fileId = fopen(filename, "w");
fileCleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
mechanics.io.writePopulationModelSelectionSection(fileId, population);
clear fileCleanup
text = string(fileread(filename));
verifyTrue(testCase, contains(text, "### Individual model-selection consensus"));
verifyTrue(testCase, contains(text, "Yeoh third order"));
verifyTrue(testCase, contains(text, "100.0%"));
verifyTrue(testCase, contains(text, "no separate consensus refit is required"));
end

function testPopulationExportIncludesSelectionSummary(testCase)
analysis = localAnalysis(["yeoh-third-order";"yeoh-third-order"]);
population = mechanics.workflow.analyzeSpecimenPopulation(analysis, localConfig());
folder = string(tempname);
cleanup = onCleanup(@() localRemoveFolder(folder)); %#ok<NASGU>
files = mechanics.io.exportPopulationAnalysis(population, folder);
verifyTrue(testCase, isfield(files, "modelSelectionSummary"));
verifyTrue(testCase, isfile(files.modelSelectionSummary));
verifyEqual(testCase, string(files.modelSelectionSummary), ...
    string(fullfile(folder, "individual_model_selection_summary.csv")));
end

function testStandardParameterPopulationSupportsDerivedFigures(testCase)
analysis = localAnalysis(["yeoh-third-order";"yeoh-third-order";"yeoh-third-order"]);
population = mechanics.workflow.analyzeSpecimenPopulation(analysis, localConfig());

verifyEqual(testCase, ...
    population.modelParameters.initialShearModulus.values.InitialShearModulus, ...
    [1;2;3], "AbsTol", 1e-12);

parameterFigure = mechanics.plotting.plotSelectedParameterPopulation( ...
    population.modelParameters);
parameterCleanup = onCleanup(@() close(parameterFigure)); %#ok<NASGU>
verifyTrue(testCase, isgraphics(parameterFigure));

shearFigure = mechanics.plotting.plotInitialShearModulusPopulation( ...
    population.modelParameters);
shearCleanup = onCleanup(@() close(shearFigure)); %#ok<NASGU>
verifyTrue(testCase, isgraphics(shearFigure));
end

function config = localConfig()
config = mechanics.config.populationAnalysisConfig();
config.minimumSpecimens = 2;
config.strainGridPointCount = 11;
config.bootstrap.enabled = false;
end

function analysis = localAnalysis(selectedModels)
selectedModels = string(selectedModels(:));
count = numel(selectedModels);
records = repmat(localRecord("", "neo-hookean", 1), count, 1);
ids = strings(count,1);
for index = 1:count
    ids(index) = "S" + index;
    records(index) = localRecord(ids(index), selectedModels(index), index);
end
analysis.records = records;
analysis.summary = table(ids, repmat("processed",count,1), ...
    ones(count,1), (1:count)', (1:count)', ...
    'VariableNames', {'SpecimenId','Status','MaximumStrain', ...
    'MaximumStress','MedianTangentModulus'});
end

function record = localRecord(id, selectedModel, slope)
strain = linspace(0,1,11)';
specimen.id = string(id);
specimen.processed.strain = strain;
specimen.processed.stress = slope .* strain;
specimen.analysis.tangentModulus.strain = strain;
specimen.analysis.tangentModulus.tangentModulusForPlot = ...
    slope .* ones(size(strain));

candidateNames = ["neo-hookean";"mooney-rivlin";"yeoh-third-order"];
for index = 1:numel(candidateNames)
    modelRecords(index).modelName = candidateNames(index); %#ok<AGROW>
    modelRecords(index).succeeded = true;
    modelRecords(index).windowFraction = 1;
    modelRecords(index).fitResult.modelName = candidateNames(index);
    modelRecords(index).fitResult.parameterNames = localParameterNames(candidateNames(index));
    modelRecords(index).fitResult.parameters = localParameterValues(candidateNames(index), slope);
end
specimen.modelSelection.records = modelRecords;
specimen.modelSelection.selection.hasEligibleModel = true;
specimen.modelSelection.selection.bestModel = string(selectedModel);

record.index = 1;
record.specimenId = string(id);
record.sheetName = string(id);
record.status = "processed";
record.quality = struct();
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";
end

function names = localParameterNames(modelName)
switch string(modelName)
    case "neo-hookean"
        names = "mu";
    case "mooney-rivlin"
        names = ["C10";"C01"];
    case "yeoh-third-order"
        names = ["C10";"C20";"C30"];
end
end

function values = localParameterValues(modelName, slope)
switch string(modelName)
    case "neo-hookean"
        values = slope;
    case "mooney-rivlin"
        values = [slope/4;slope/4];
    case "yeoh-third-order"
        values = [slope/2;0;0];
end
end

function localDelete(filename)
if isfile(filename)
    delete(filename);
end
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
