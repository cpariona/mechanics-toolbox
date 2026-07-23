function tests = test_study_reporting
tests = functiontests(localfunctions);
end

function setupOnce(~)
testFile = mfilename("fullpath");
repositoryRoot = fileparts(fileparts(testFile));
addpath(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));
end

function testFigureExport(testCase)
study = localStudy();
config = localConfig();
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config.outputFolder = folder;
files = mechanics.plotting.exportTensileStudyFigures(study, config);
verifyTrue(testCase, isfile(files.individualCurves));
verifyFalse(testCase, isfield(files, "populationCurve"));
verifyFalse(testCase, isfield(files, "peakMetrics"));
verifyFalse(testCase, isfield(files, "tangentModulus"));
end

function testMarkdownReport(testCase)
study = localStudy();
config = localConfig();
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config.outputFolder = folder;
files = mechanics.io.exportTensileStudyReport(study, config);
verifyTrue(testCase, isfile(files.report));
verifyTrue(testCase, isfile(files.individualCurves));
text = fileread(files.report);
verifyTrue(testCase, contains(text, "# Tensile study report"));
verifyTrue(testCase, contains(text, "sample-01"));
verifyTrue(testCase, contains(text, "individual_curves.png"));
end

function testDefaultConfiguration(testCase)
config = mechanics.config.studyReportConfig();
verifyEqual(testCase, config.figureFormat, "png");
verifyTrue(testCase, config.includeIndividualCurves);
verifyTrue(testCase, config.includeTangentModulus);
verifyTrue(testCase, config.closeFiguresAfterExport);
end

function config = localConfig()
config = mechanics.config.studyReportConfig();
config.studyTitle = "Tensile study report";
config.includePopulationCurve = false;
config.includePeakMetrics = false;
config.includeFractureMetrics = false;
config.includeTangentModulus = false;
config.figureResolution = 72;
end

function study = localStudy()
specimen.id = "sample-01";
specimen.processed.strain = [0; 0.1; 0.2; 0.3];
specimen.processed.stress = [0; 1; 2; 3];
specimen.processed.units.force = "N";
specimen.processed.units.displacement = "mm";
specimen.processed.units.strain = "-";
specimen.processed.units.stress = "MPa";

record.index = 1;
record.specimenId = "sample-01";
record.sheetName = "sample-01";
record.status = "processed";
record.segmentation = struct();
record.quality = struct();
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";

study.sourceFile = "synthetic.xlsx";
study.createdAt = datetime("now");
study.exclusion.indices = [];
study.exclusion.specimenIds = strings(0,1);
study.exclusion.sheetNames = strings(0,1);
study.exclusion.reason = "";
study.exclusion.count = 0;
study.analysis.records = record;
study.analysis.summary = table( ...
    1, "sample-01", "sample-01", "processed", ...
    false, 4, 3, 3, 4, 0, true, "", 4, 0, 0, ...
    0.3, 3, 10, "neo-hookean", 0, 1, "", "", ...
    'VariableNames', { ...
    'Index','SpecimenId','SheetName','Status', ...
    'FractureDetected','PeakIndex','PeakForce','PeakDisplacement', ...
    'AnalysisEndIndex','PostPeakDropFraction', ...
    'QualityPassed','FailedQualityChecks','ObservationCount', ...
    'NonfiniteFraction','DisplacementReversalFraction', ...
    'MaximumStrain','MaximumStress','MedianTangentModulus', ...
    'BestModel','BestModelRMSE','BestModelRSquared', ...
    'ErrorIdentifier','ErrorMessage'});
study.population = struct();
study.populationStatus = "disabled";
study.provenance.sourceFile = study.sourceFile;
study.provenance.sourceFileBytes = 0;
study.provenance.matlabRelease = string(version("-release"));
study.provenance.platform = string(computer);
study.provenance.specimenCount = 1;
study.provenance.processedSpecimenCount = 1;
study.provenance.qualityFailedSpecimenCount = 0;
study.provenance.failedSpecimenCount = 0;
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end