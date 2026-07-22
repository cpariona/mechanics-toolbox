function tests = test_constitutive_study_report
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testMarkdownReportContainsIntegratedSections(testCase)
[batch, population, inference] = localInputs();
config = localConfig();
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
config.outputFolder = folder;
files = mechanics.io.exportConstitutiveStudyReport( ...
    batch, population, inference, config);
verifyTrue(testCase, isfile(files.report));
text = fileread(files.report);
verifyTrue(testCase, contains(text, "# Constitutive study report"));
verifyTrue(testCase, contains(text, "## Model selection"));
verifyTrue(testCase, contains(text, "## Selected-model parameters"));
verifyTrue(testCase, contains(text, "## Inferential group comparisons"));
verifyTrue(testCase, contains(text, "neo-hookean"));
end

function testFigureExportCreatesFiles(testCase)
[batch, population, inference] = localInputs();
config = mechanics.config.constitutiveStudyReportConfig();
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
config.outputFolder = folder;
config.figureResolution = 72;
files = mechanics.plotting.exportConstitutiveStudyFigures( ...
    batch, population, inference, config);
verifyTrue(testCase, isfile(files.modelSelection));
verifyTrue(testCase, isfile(files.selectedParameters));
verifyTrue(testCase, isfile(files.groupInference));
end

function testFiguresCanBeDisabled(testCase)
[batch, population, inference] = localInputs();
config = localConfig();
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
config.outputFolder = folder;
files = mechanics.io.exportConstitutiveStudyReport( ...
    batch, population, inference, config);
verifyEqual(testCase, fieldnames(files), {'report'});
end

function config = localConfig()
config = mechanics.config.constitutiveStudyReportConfig();
config.includeModelSelectionFigure = false;
config.includeParameterFigure = false;
config.includeInferenceFigure = false;
end

function [batch, population, inference] = localInputs()
batch.specimenCount = 4;
batch.successfulSpecimenCount = 4;
batch.selectedSpecimenCount = 4;
batch.modelSummary = table("neo-hookean", 4, 1, ...
    'VariableNames', {'ModelName','SelectionCount','SelectionFraction'});

population.parameterObservationCount = 4;
population.specimenCount = 4;
population.parameterTable = table( ...
    ["S1";"S2";"S3";"S4"], ["A";"A";"B";"B"], ...
    repmat("neo-hookean",4,1), repmat("mu",4,1), ...
    [10;11;20;21], nan(4,1), nan(4,1), nan(4,1), ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter', ...
    'Value','BootstrapLower','BootstrapMedian','BootstrapUpper'});
population.overallSummary = table("neo-hookean", "mu", 4, 15.5, ...
    std([10 11 20 21]), 15.5, 10, 21, std([10 11 20 21])/15.5, true, ...
    'VariableNames', {'ModelName','Parameter','SpecimenCount','Mean', ...
    'StandardDeviation','Median','Minimum','Maximum', ...
    'CoefficientOfVariation','MeetsMinimumCount'});
population.groupSummary = table( ...
    ["A";"B"], repmat("neo-hookean",2,1), repmat("mu",2,1), ...
    [2;2], [10.5;20.5], [0.7071;0.7071], [10.5;20.5], ...
    [10;20], [11;21], [0.0673;0.0345], [true;true], ...
    'VariableNames', {'Group','ModelName','Parameter','SpecimenCount', ...
    'Mean','StandardDeviation','Median','Minimum','Maximum', ...
    'CoefficientOfVariation','MeetsMinimumCount'});

inference.comparisonCount = 1;
inference.successfulComparisonCount = 1;
inference.significantComparisonCount = 1;
inference.comparisonTable = table( ...
    "neo-hookean", "mu", "A", "B", 2, 2, 10.5, 20.5, -10, -10, ...
    -11, -9, -5, -1, 0.01, 0.01, true, "", "", ...
    'VariableNames', {'ModelName','Parameter','Group1','Group2', ...
    'Group1Count','Group2Count','Group1Mean','Group2Mean', ...
    'MeanDifference','MedianDifference','ConfidenceIntervalLower', ...
    'ConfidenceIntervalUpper','HedgesG','CliffsDelta', ...
    'PermutationPValue','AdjustedPValue','Significant', ...
    'ErrorIdentifier','ErrorMessage'});
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end
