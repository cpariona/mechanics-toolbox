function tests = test_tensile_application_range_figures
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testMechanicalAxisLabelsUseMeasuresAndUnits(testCase)
verifyEqual(testCase, mechanics.plotting.mechanicalAxisLabel( ...
    "deformation", "engineering-strain", "1"), ...
    "Engineering strain [mm/mm]");
verifyEqual(testCase, mechanics.plotting.mechanicalAxisLabel( ...
    "deformation", "true-strain", "dimensionless"), ...
    "True strain [mm/mm]");
verifyEqual(testCase, mechanics.plotting.mechanicalAxisLabel( ...
    "stress", "nominal", "MPa"), "Nominal stress [MPa]");
verifyEqual(testCase, mechanics.plotting.mechanicalAxisLabel( ...
    "residual", "cauchy", "kPa"), ...
    "Cauchy stress residual [kPa]");
verifyEqual(testCase, mechanics.plotting.mechanicalAxisLabel( ...
    "compression-magnitude-residual", "nominal", "MPa"), ...
    "Nominal compressive-stress magnitude residual [MPa]");
end

function testFitFigureUsesOneSharedPrediction(testCase)
result = localResult();
figureHandle = mechanics.plotting.plotTensileApplicationRangeFit(result);
cleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
axesHandles = findall(figureHandle, "Type", "axes");
labels = string(get(findall(axesHandles, "Type", "line"), "DisplayName"));
verifyEqual(testCase, nnz(contains(labels, "Shared prediction")), 1);
end

function testCompressionFigureUsesOnePredictionAndMagnitudeResidual(testCase)
result = localResult();
figureHandle = ...
    mechanics.plotting.plotTensileApplicationRangeCompressionValidation(result);
cleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
axesHandles = findall(figureHandle, "Type", "axes");
labels = string(get(findall(axesHandles, "Type", "line"), "DisplayName"));
verifyEqual(testCase, nnz(contains(labels, "Shared tensile-calibrated prediction")), 1);
titles = string(get(findall(figureHandle, "Type", "axes"), "Title"));
titleText = strings(numel(titles), 1);
for index = 1:numel(titles)
    titleText(index) = string(titles(index).String);
end
verifyTrue(testCase, any(contains(titleText, ...
    "|measured| - |shared prediction|")));
end

function testExportIncludesUnitAwareFiguresAndTables(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() localRemoveFolder(folder)); %#ok<NASGU>
config = localConfig();
config.export.enabled = true;
config.export.outputFolder = folder;
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    localStudy("tension", ["t1"; "t2"], 0.4, 51), config, ...
    localStudy("compression", ["c1"; "c2"], 0.4, 41));

required = ["tensileFitFigure", "tensileFitFigureFig", ...
    "rangeSensitivityFigure", "rangeSensitivityFigureFig", ...
    "compressionValidationFigure", "compressionValidationFigureFig"];
verifyTrue(testCase, all(isfield(result.outputFiles, required)));
for index = 1:numel(required)
    verifyTrue(testCase, isfile(result.outputFiles.(required(index))));
end

parameterTable = readtable(result.outputFiles.selectedParameters, ...
    "TextType", "string");
verifyTrue(testCase, ismember("Unit", ...
    string(parameterTable.Properties.VariableNames)));
verifyEqual(testCase, string(parameterTable.Unit), "MPa");

specimenTable = readtable(result.outputFiles.tensileSpecimenSummary, ...
    "TextType", "string");
verifyTrue(testCase, all(ismember(["StrainUnit","StressUnit"], ...
    string(specimenTable.Properties.VariableNames))));
verifyEqual(testCase, unique(string(specimenTable.StrainUnit)), "mm/mm");
verifyEqual(testCase, unique(string(specimenTable.StressUnit)), "MPa");

compressionTable = readtable( ...
    result.outputFiles.compressionValidationSummary, "TextType", "string");
verifyEqual(testCase, unique(string(compressionTable.StrainUnit)), "mm/mm");
verifyEqual(testCase, unique(string(compressionTable.StressUnit)), "MPa");

reportText = string(fileread(result.outputFiles.report));
verifyTrue(testCase, contains(reportText, "Deformation unit: `mm/mm`"));
verifyTrue(testCase, contains(reportText, ...
    "Stress and parameter unit: `MPa`"));
verifyTrue(testCase, contains(reportText, ...
    "|measured| - |prediction|"));
verifyTrue(testCase, contains(reportText, "tensile_fit_and_residuals.png"));
verifyTrue(testCase, contains(reportText, "range_sensitivity.png"));
verifyTrue(testCase, contains(reportText, "compression_validation.png"));
end

function result = localResult()
config = localConfig();
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    localStudy("tension", ["t1"; "t2"], 0.4, 51), config, ...
    localStudy("compression", ["c1"; "c2"], 0.4, 41));
end

function config = localConfig()
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.fitRange = [0, 0.30];
config.rangeSensitivity.maximumDeformations = [0.10; 0.20; 0.30];
config.candidateModelNames = "neo-hookean";
config.selection.tieBreakOrder = "neo-hookean";
config.minimumObservationsPerSpecimen = 8;
config.minimumSpecimens = 2;
config.fitting.numberOfStarts = 2;
config.fitting.randomSeed = 3;
config.export.enabled = false;
end

function study = localStudy(mode, specimenIds, mu, pointCount)
specimenIds = string(specimenIds(:));
records = repmat(localRecord(mode, "", mu, pointCount), numel(specimenIds), 1);
for index = 1:numel(specimenIds)
    records(index) = localRecord(mode, specimenIds(index), mu, pointCount);
    records(index).index = index;
end
study.sourceFile = "synthetic.xlsx";
study.sourceFiles = "synthetic.xlsx";
study.analysis.records = records;
study.populationStatus = "completed";
study.config = struct();
study.provenance.inputType = "synthetic";
study.createdAt = datetime(2026, 8, 3);
end

function record = localRecord(mode, specimenId, mu, pointCount)
if mode == "tension"
    deformation = linspace(0, 0.30, pointCount)';
else
    deformation = linspace(0, -0.25, pointCount)';
end
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
stress = mechanics.models.evaluateModel("neo-hookean", deformation, mu, context);
specimen.id = string(specimenId);
specimen.processed.strain = deformation;
specimen.processed.stress = stress;
specimen.processed.units.strain = "1";
specimen.processed.units.stress = "MPa";
specimen.processed.mechanicsConfig.strainMeasure = "engineering";
specimen.processed.mechanicsConfig.stressMeasure = "engineering";
record.index = 1;
record.specimenId = string(specimenId);
record.sheetName = "Sheet-" + specimenId;
record.status = "processed";
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
