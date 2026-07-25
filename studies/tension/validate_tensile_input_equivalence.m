%% VALIDATE TENSILE INPUT EQUIVALENCE
% Compare the maintained workbook input with its normalized dataset using
% the same downstream tensile-study configuration.

restoredefaultpath
clear classes
clear functions
clear
clc
close all

repositoryFolder = 'D:\Escritorio\mechanics-toolbox';
cd(repositoryFolder)
startup

inputFile = fullfile( ...
    repositoryFolder, ...
    "data", ...
    "raw", ...
    "Tension_ASTM_D412_ECOFLEX0050_test.xlsx");

config = mechanics.config.tensileStudyConfig();
config.extraction.extractor = "auto";
config.extraction.defaultInitialLength = 25;
config.specimens.excludeIndices = 1;
config.specimens.exclusionReason = ...
    "Manual exclusion after visual inspection";
config.specimens.preloadForceOverrides = [];

zeroConfig = ...
    config.datasetAnalysis.processingConfig.preprocessing.zeroReference;
zeroConfig.method = "preload-threshold";
zeroConfig.preloadForce = 0.10;
zeroConfig.sustainedPoints = 3;
config.datasetAnalysis.processingConfig.preprocessing.zeroReference = ...
    zeroConfig;

config.datasetAnalysis.fitting.enabled = false;
config.peakAnalysis.enabled = true;
config.population.enabled = true;
config.population.config.centralStatistic = "median";
config.population.config.strainGridPointCount = 201;
config.population.config.minimumSpecimens = 2;
config.population.config.bootstrap.enabled = false;
config.export.enabled = false;

normalizedConfig = config;
normalizedConfig.input.type = "workbook";
[dataset, inputInfo] = mechanics.workflow.normalizeTensileStudyInput( ...
    inputFile, normalizedConfig);

workbookStudy = mechanics.workflow.runTensileStudy(inputFile, config);

datasetConfig = config;
datasetConfig.input.type = "dataset";
datasetStudy = mechanics.workflow.runTensileStudy(dataset, datasetConfig);

assert(inputInfo.specimenCount == numel(dataset.specimens), ...
    "Normalized input metadata does not match the dataset specimen count.")
assert(isequal(workbookStudy.analysis.summary.Status, ...
    datasetStudy.analysis.summary.Status), ...
    "Workbook and dataset inputs produced different specimen statuses.")
assert(isequal(workbookStudy.analysis.summary.SpecimenId, ...
    datasetStudy.analysis.summary.SpecimenId), ...
    "Workbook and dataset inputs produced different specimen identifiers.")

localVerifyNumericTableColumn( ...
    workbookStudy.analysis.summary, datasetStudy.analysis.summary, ...
    "MaximumStrain", 1e-12);
localVerifyNumericTableColumn( ...
    workbookStudy.analysis.summary, datasetStudy.analysis.summary, ...
    "MaximumStress", 1e-12);
localVerifyProcessedCurves(workbookStudy, datasetStudy, 1e-12);
localVerifyPopulation(workbookStudy, datasetStudy, 1e-12);

fprintf("Workbook and normalized-dataset studies are equivalent.\n")
fprintf("Input type: %s -> %s\n", ...
    workbookStudy.input.type, datasetStudy.input.type)
fprintf("Processed specimens: %d\n", ...
    nnz(workbookStudy.analysis.summary.Status == "processed"))

disp(workbookStudy.analysis.summary)

function localVerifyNumericTableColumn(first, second, variableName, tolerance)
if ~ismember(variableName, string(first.Properties.VariableNames)) || ...
        ~ismember(variableName, string(second.Properties.VariableNames))
    return;
end
firstValues = first.(variableName);
secondValues = second.(variableName);
assert(isequal(size(firstValues), size(secondValues)), ...
    "Summary column %s has different sizes.", variableName)
finiteMask = isfinite(firstValues) & isfinite(secondValues);
assert(all(isnan(firstValues(~finiteMask)) == isnan(secondValues(~finiteMask))), ...
    "Summary column %s has incompatible missing values.", variableName)
assert(all(abs(firstValues(finiteMask) - secondValues(finiteMask)) <= tolerance), ...
    "Summary column %s differs between input forms.", variableName)
end

function localVerifyProcessedCurves(first, second, tolerance)
firstRecords = first.analysis.records;
secondRecords = second.analysis.records;
assert(numel(firstRecords) == numel(secondRecords), ...
    "Input forms produced different record counts.")
for index = 1:numel(firstRecords)
    if firstRecords(index).status ~= "processed"
        continue;
    end
    assert(secondRecords(index).status == "processed", ...
        "A processed workbook record was not processed from the dataset input.")
    firstSpecimen = firstRecords(index).specimen;
    secondSpecimen = secondRecords(index).specimen;
    assert(all(abs(firstSpecimen.processed.strain - ...
        secondSpecimen.processed.strain) <= tolerance), ...
        "Processed strain differs for specimen %s.", firstRecords(index).specimenId)
    assert(all(abs(firstSpecimen.processed.stress - ...
        secondSpecimen.processed.stress) <= tolerance), ...
        "Processed stress differs for specimen %s.", firstRecords(index).specimenId)
end
end

function localVerifyPopulation(first, second, tolerance)
assert(first.populationStatus == second.populationStatus, ...
    "Population status differs between input forms.")
if first.populationStatus ~= "completed"
    return;
end
assert(all(abs(first.population.curves.strain - ...
    second.population.curves.strain) <= tolerance), ...
    "Population strain grids differ between input forms.")
assert(all(abs(first.population.curves.centralStress - ...
    second.population.curves.centralStress) <= tolerance), ...
    "Population central stress differs between input forms.")
end
