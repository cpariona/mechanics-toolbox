function tests = test_compression_reporting
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testPopulationReportExportsImageAndFigurePairs(testCase)
study = localPopulationStudy();
config = mechanics.config.compressionStudyReportConfig();
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config.outputFolder = folder;
config.figureResolution = 72;

files = mechanics.io.exportCompressionStudyReport(study, config);

expectedImages = [
    "individual_curves.png"
    "population_curve.png"
    "tangent_modulus.png"
    "population_tangent_modulus.png"
    "cycle_diagnostics.png"
];
for index = 1:numel(expectedImages)
    verifyTrue(testCase, isfile(fullfile(folder, expectedImages(index))));
    [~, baseName] = fileparts(expectedImages(index));
    verifyTrue(testCase, isfile(fullfile(folder, baseName + ".fig")));
end
verifyTrue(testCase, isfile(files.report));
end

function testPopulationMarkdownContainsStudyContracts(testCase)
study = localPopulationStudy();
config = mechanics.config.compressionStudyReportConfig();
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config.outputFolder = folder;
config.figureResolution = 72;

files = mechanics.io.exportCompressionStudyReport(study, config);
text = string(fileread(files.report));

verifyTrue(testCase, contains(text, "Processed | 2"));
verifyTrue(testCase, contains(text, "Excluded | 1"));
verifyTrue(testCase, contains(text, "Initial thickness outside tolerance"));
verifyTrue(testCase, contains(text, "yeoh"));
verifyTrue(testCase, contains(text, "population_curve.png"));
verifyFalse(testCase, contains(text, ".fig)"));
end

function study = localPopulationStudy()
records = repmat(localRecord(), 3, 1);
records(1).index = 1;
records(1).specimenId = "excluded-01";
records(1).sheetName = "excluded-01";
records(1).status = "skipped";
records(1).specimen = struct();

records(2) = localProcessedRecord(2, "sample-01", 1.0);
records(3) = localProcessedRecord(3, "sample-02", 1.1);

study.sourceFile = "compression.xlsx";
study.sourceFiles = "compression.xlsx";
study.createdAt = datetime("now");
study.analysis.records = records;
study.analysis.summary = table( ...
    (1:3)', ["excluded-01"; "sample-01"; "sample-02"], ...
    ["skipped"; "processed"; "processed"], ...
    [NaN; 4; 4], [NaN; 0.3; 0.3], [NaN; 3.0; 3.3], ...
    [NaN; 10; 11], [""; "yeoh"; "yeoh"], ...
    [""; ""; ""], [""; ""; ""], ...
    'VariableNames', { ...
        'Index','SpecimenId','Status','ObservationCount', ...
        'MaximumStrain','MaximumStress','MedianTangentModulus', ...
        'SelectedModel','ErrorIdentifier','ErrorMessage'});
study.exclusion.indices = 1;
study.exclusion.specimenIds = "excluded-01";
study.exclusion.sheetNames = "excluded-01";
study.exclusion.reason = "Initial thickness outside tolerance";
study.exclusion.count = 1;

strain = [-0.3; -0.2; -0.1; 0];
stressMatrix = [-3.0, -3.3; -2.0, -2.2; -1.0, -1.1; 0, 0];
study.populationStatus = "completed";
study.population.specimenCount = 2;
study.population.curves.strain = strain;
study.population.curves.stressMatrix = stressMatrix;
study.population.curves.meanStress = mean(stressMatrix, 2);
study.population.curves.medianStress = median(stressMatrix, 2);
study.population.curves.centralStress = median(stressMatrix, 2);
study.population.curves.centralStatistic = "median";
study.population.curves.confidenceLower = min(stressMatrix, [], 2);
study.population.curves.confidenceUpper = max(stressMatrix, [], 2);
study.population.tangentModulusStatus = "completed";
study.population.tangentModulus.strain = strain;
study.population.tangentModulus.modulusMatrix = [10, 11; 10, 11; 10, 11; 10, 11];
study.population.tangentModulus.centralModulus = [10.5; 10.5; 10.5; 10.5];
study.population.tangentModulus.centralStatistic = "median";
study.population.tangentModulus.confidenceLower = [10; 10; 10; 10];
study.population.tangentModulus.confidenceUpper = [11; 11; 11; 11];
study.population.modelParameters.values = table();
study.population.modelParameters.summary = table( ...
    "yeoh", "C10", 2, 0.05, 0.01, 0.05, 0.04, 0.06, 0.2, true, ...
    'VariableNames', { ...
        'ModelName','Parameter','SpecimenCount','Mean', ...
        'StandardDeviation','Median','Minimum','Maximum', ...
        'CoefficientOfVariation','MeetsMinimumCount'});
study.provenance.matlabRelease = string(version("-release"));
study.provenance.platform = string(computer);
study.provenance.inputType = "workbook";
end

function record = localProcessedRecord(index, specimenId, scale)
record = localRecord();
record.index = index;
record.specimenId = specimenId;
record.sheetName = specimenId;
record.status = "processed";
record.specimen.id = specimenId;
record.specimen.processed.strain = [-0.3; -0.2; -0.1; 0];
record.specimen.processed.stress = scale .* [-3; -2; -1; 0];
record.specimen.processed.displacement = [-3; -2; -1; 0];
record.specimen.processed.force = scale .* [-6; -4; -2; 0];
record.specimen.processed.units.force = "N";
record.specimen.processed.units.displacement = "mm";
record.specimen.processed.units.strain = "-";
record.specimen.processed.units.stress = "MPa";
record.specimen.fullCycleRaw.displacement = [0; 1; 2; 3; 2; 1; 0];
record.specimen.fullCycleRaw.force = scale .* [0; 2; 4; 6; 4; 2; 0];
record.specimen.analysis.tangentModulus.strain = [-0.3; -0.2; -0.1; 0];
record.specimen.analysis.tangentModulus.tangentModulusForPlot = scale .* [10; 10; 10; 10];
record.specimen.analysis.tangentModulus.summaryStrainRange = [-0.3, 0];
end

function record = localRecord()
record.index = NaN;
record.specimenId = "";
record.sheetName = "";
record.status = "pending";
record.cycle = struct();
record.cycleMetrics = struct();
record.specimen = struct();
record.errorIdentifier = "";
record.errorMessage = "";
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
