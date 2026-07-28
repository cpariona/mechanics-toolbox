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
verifyTrue(testCase, isfile(fullfile(folder, "individual_curves.fig")));
verifyFalse(testCase, isfield(files, "populationCurve"));
verifyFalse(testCase, isfield(files, "peakMetrics"));
verifyFalse(testCase, isfield(files, "tangentModulus"));
verifyFalse(testCase, isfield(files, "populationTangentModulus"));
end

function testPopulationTangentModulusFigureExport(testCase)
study = localStudy();
study.population.tangentModulusStatus = "completed";
study.population.tangentModulus = localPopulationTangentModulus();
config = localConfig();
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config.outputFolder = folder;
config.includeIndividualCurves = false;
config.includeTangentModulus = true;

files = mechanics.plotting.exportTensileStudyFigures(study, config);

verifyTrue(testCase, isfield(files, "populationTangentModulus"));
verifyTrue(testCase, isfile(files.populationTangentModulus));
verifyTrue(testCase, isfile(fullfile(folder, "population_tangent_modulus.fig")));
verifyFalse(testCase, isfield(files, "tangentModulus"));
end

function testUnavailablePopulationTangentModulusIsNotExported(testCase)
study = localStudy();
study.population.tangentModulusStatus = "unavailable";
study.population.tangentModulus = struct();
config = localConfig();
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config.outputFolder = folder;
config.includeIndividualCurves = false;
config.includeTangentModulus = true;

files = mechanics.plotting.exportTensileStudyFigures(study, config);

verifyFalse(testCase, isfield(files, "populationTangentModulus"));
verifyFalse(testCase, isfile(fullfile(folder, "population_tangent_modulus.fig")));
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
verifyTrue(testCase, isfile(fullfile(folder, "individual_curves.fig")));
text = fileread(files.report);
verifyTrue(testCase, contains(text, "# Tensile study report"));
verifyTrue(testCase, contains(text, "sample-01"));
verifyTrue(testCase, contains(text, "individual_curves.png"));
verifyFalse(testCase, contains(text, "individual_curves.fig"));
end

function testDefaultConfiguration(testCase)
config = mechanics.config.tensileStudyReportConfig();
verifyEqual(testCase, config.figureFormat, "png");
verifyTrue(testCase, config.includeIndividualCurves);
verifyTrue(testCase, config.includePeakMetrics);
verifyTrue(testCase, config.includeTangentModulus);
verifyTrue(testCase, config.closeFiguresAfterExport);
end

function config = localConfig()
config = mechanics.config.tensileStudyReportConfig();
config.studyTitle = "Tensile study report";
config.includePopulationCurve = false;
config.includePeakMetrics = false;
config.includeTangentModulus = false;
config.figureResolution = 72;
end

function study = localStudy()
specimen.id = "sample-01";
specimen.processed.strain = [0; 0.1; 0.2; 0.3];
specimen.processed.stress = [0; 1; 2; 3];
specimen.processed.raw.force = [0; 2; 4; 6];
specimen.processed.raw.displacement = [0; 1; 2; 3];
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
    4, 3, 3, 4, 0, true, "", 4, 0, 0, ...
    0.3, 3, 10, "neo-hookean", 0, 1, "", "", ...
    'VariableNames', { ...
    'Index','SpecimenId','SheetName','Status', ...
    'PeakIndex','PeakForce','PeakDisplacement', ...
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

function tangent = localPopulationTangentModulus()
tangent.strain = [0.1; 0.2; 0.3];
tangent.modulusMatrix = [2, 4; 3, 5; 4, 6];
tangent.meanModulus = [3; 4; 5];
tangent.medianModulus = [3; 4; 5];
tangent.centralStatistic = "mean";
tangent.centralModulus = [3; 4; 5];
tangent.standardDeviation = [sqrt(2); sqrt(2); sqrt(2)];
tangent.standardError = [1; 1; 1];
tangent.confidenceLower = [2.5; 3.5; 4.5];
tangent.confidenceUpper = [3.5; 4.5; 5.5];
tangent.specimenCountByPoint = [2; 2; 2];
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
