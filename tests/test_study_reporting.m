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
config.includePopulationTangentModulus = true;

files = mechanics.plotting.exportTensileStudyFigures(study, config);

verifyTrue(testCase, isfield(files, "populationTangentModulus"));
verifyTrue(testCase, isfile(files.populationTangentModulus));
verifyTrue(testCase, isfile(fullfile(folder, "population_tangent_modulus.fig")));
verifyFalse(testCase, isfield(files, "tangentModulus"));
end

function testIndividualAndPopulationTangentModulusControlsAreIndependent(testCase)
study = localStudy();
study.population.tangentModulusStatus = "completed";
study.population.tangentModulus = localPopulationTangentModulus();
study.analysis.records.specimen.analysis.tangentModulus = localSpecimenTangentModulus();
config = localConfig();
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config.outputFolder = folder;
config.includeIndividualCurves = false;
config.includeTangentModulus = true;
config.includePopulationTangentModulus = false;

files = mechanics.plotting.exportTensileStudyFigures(study, config);

verifyTrue(testCase, isfield(files, "tangentModulus"));
verifyFalse(testCase, isfield(files, "populationTangentModulus"));
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
config.includePopulationTangentModulus = true;

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
verifyTrue(testCase, isfile(files.fittingAudit));
verifyTrue(testCase, isfile(fullfile(folder, "fitting_audit.fig")));
text = fileread(files.report);
verifyTrue(testCase, contains(text, "# Tensile study report"));
verifyTrue(testCase, contains(text, "sample-01"));
verifyTrue(testCase, contains(text, "Maximum engineering strain (mm/mm)"));
verifyTrue(testCase, contains(text, "Maximum engineering stress (MPa)"));
verifyTrue(testCase, contains(text, "Peak force (N)"));
verifyTrue(testCase, contains(text, "Median tangent modulus (MPa)"));
verifyTrue(testCase, contains(text, "## Constitutive fitting audit"));
verifyTrue(testCase, contains(text, "### Model eligibility and selection"));
verifyTrue(testCase, contains(text, "### Window-level fitting results"));
verifyTrue(testCase, contains(text, "InitialShearModulus"));
verifyTrue(testCase, contains(text, "mu=1.25"));
verifyTrue(testCase, contains(text, "### Constitutive fitting audit"));
verifyTrue(testCase, contains(text, "fitting_audit.png"));
verifyTrue(testCase, contains(text, "### Individual curves"));
verifyTrue(testCase, contains(text, "individual_curves.png"));
verifyFalse(testCase, contains(text, "individual_curves.fig"));
verifyTrue(testCase, contains(text, "Strain measure: `engineering`"));
verifyTrue(testCase, contains(text, "Strain unit: `mm/mm`"));
verifyTrue(testCase, contains(text, "Stress measure: `engineering`"));
verifyTrue(testCase, contains(text, "Area evolution: `incompressible`"));
verifyTrue(testCase, contains(text, ...
    "Tangent-modulus summary strain range: `[0.1, 0.3] mm/mm`"));
verifyTrue(testCase, contains(text, ...
    "Candidate models: `Neo-Hookean, Yeoh third order`"));
verifyTrue(testCase, contains(text, "Model-ranking metric: `BIC`"));
verifyTrue(testCase, contains(text, "Fit starts: `8`"));
verifyTrue(testCase, contains(text, "Fit random seed: `1`"));
end

function testMarkdownReportIncludesPopulationSummary(testCase)
study = localStudy();
study.populationStatus = "completed";
study.population.specimenCount = 3;
study.population.curves.centralStatistic = "median";
study.population.tangentModulusStatus = "completed";
study.population.modelParameters.summary = table( ...
    "neo-hookean", "mu", 3, 1.25, 0.10, ...
    'VariableNames', {'Model','Parameter','Count','Mean','StandardDeviation'});
config = localConfig();
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config.outputFolder = folder;
files = mechanics.io.exportTensileStudyReport(study, config);
text = fileread(files.report);
verifyTrue(testCase, contains(text, "## Population analysis"));
verifyTrue(testCase, contains(text, "Retained specimen count: 3"));
verifyTrue(testCase, contains(text, "Central statistic: `median`"));
verifyTrue(testCase, contains(text, ...
    "### Individually selected-model parameter summary"));
verifyTrue(testCase, contains(text, "Neo-Hookean"));
verifyTrue(testCase, contains(text, "mu"));
verifyTrue(testCase, contains(text, "Unit"));
verifyTrue(testCase, contains(text, "MPa"));
end

function testDefaultConfiguration(testCase)
config = mechanics.config.tensileStudyReportConfig();
verifyEqual(testCase, config.figureFormat, "png");
verifyTrue(testCase, config.includeIndividualCurves);
verifyTrue(testCase, config.includePeakMetrics);
verifyTrue(testCase, config.includeTangentModulus);
verifyTrue(testCase, config.includePopulationTangentModulus);
verifyTrue(testCase, config.closeFiguresAfterExport);
end

function config = localConfig()
config = mechanics.config.tensileStudyReportConfig();
config.studyTitle = "Tensile study report";
config.includePopulationCurve = false;
config.includePeakMetrics = false;
config.includeTangentModulus = false;
config.includePopulationTangentModulus = false;
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
specimen.modelSelection = localModelSelection();

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
study.config.datasetAnalysis.processingConfig.mechanics.strainMeasure = ...
    "engineering";
study.config.datasetAnalysis.processingConfig.mechanics.stressMeasure = ...
    "engineering";
study.config.datasetAnalysis.processingConfig.mechanics.areaEvolution = ...
    "incompressible";
study.config.datasetAnalysis.processingConfig.analysis.summaryStrainRange = ...
    [0.1, 0.3];
study.config.datasetAnalysis.fitting.modelNames = ...
    ["neo-hookean"; "yeoh-third-order"];
study.config.datasetAnalysis.fitting.selectionConfig.rankingMetric = "BIC";
study.config.datasetAnalysis.fitting.fitConfig.numberOfStarts = 8;
study.config.datasetAnalysis.fitting.fitConfig.randomSeed = 1;
study.provenance.sourceFile = study.sourceFile;
study.provenance.sourceFileBytes = 0;
study.provenance.matlabRelease = string(version("-release"));
study.provenance.platform = string(computer);
study.provenance.specimenCount = 1;
study.provenance.processedSpecimenCount = 1;
study.provenance.qualityFailedSpecimenCount = 0;
study.provenance.failedSpecimenCount = 0;
end

function selection = localModelSelection()
selection.summary = table( ...
    "neo-hookean", 3, 3, 3, 1, 0.05, 0.99, -10, -9, 0.08, true, true, ...
    {{"mu"}}, {[1.20]}, {[0.05]}, {[0.04]}, ...
    'VariableNames', {'Model','WindowCount','SuccessfulWindowCount', ...
    'ConvergedWindowCount','FullWindowParameterCount','FullWindowRMSE', ...
    'FullWindowRSquared','FullWindowAIC','FullWindowBIC', ...
    'MaximumRelativeParameterCV','ParameterStable','Eligible', ...
    'ParameterNames','ParameterMeans','ParameterStd','ParameterCV'});
selection.selection.hasEligibleModel = true;
selection.selection.bestModel = "neo-hookean";
selection.selection.rankingMetric = "BIC";
selection.selection.reason = "Synthetic selection";
selection.selectionConfig.maximumRelativeParameterCV = 0.50;
fractions = [0.50, 0.75, 1.00];
parameters = [1.20, 1.25, 1.30];
for index = 1:numel(fractions)
    fit.modelName = "neo-hookean";
    fit.parameterNames = "mu";
    fit.parameters = parameters(index);
    fit.deformation = [0; fractions(index)];
    fit.measuredStress = [0; 1];
    fit.predictedStress = [0; 1];
    fit.residuals = [0; 0];
    fit.metrics.rmse = 0.05;
    fit.metrics.rSquared = 0.99;
    fit.metrics.aic = -10;
    fit.metrics.bic = -9;
    fit.converged = true;
    selection.records(index).modelName = "neo-hookean"; %#ok<AGROW>
    selection.records(index).windowFraction = fractions(index);
    selection.records(index).maximumDeformation = fractions(index);
    selection.records(index).observationCount = 20;
    selection.records(index).fitResult = fit;
    selection.records(index).succeeded = true;
    selection.records(index).errorIdentifier = "";
    selection.records(index).errorMessage = "";
end
end

function tangent = localSpecimenTangentModulus()
tangent.strain = [0.1; 0.2; 0.3];
tangent.tangentModulusForPlot = [2; 3; 4];
tangent.summaryStrainRange = [0.1, 0.3];
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
    rmdir(folder,'s');
end
end