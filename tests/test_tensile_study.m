function tests = test_tensile_study
tests = functiontests(localfunctions);
end

function setupOnce(~)
testFile = mfilename("fullpath");
repositoryRoot = fileparts(fileparts(testFile));
addpath(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));
end

function testEndToEndStudy(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
study = mechanics.workflow.runTensileStudy( ...
    filename, localStudyConfig());
verifyEqual(testCase, height(study.analysis.summary), 2);
verifyEqual(testCase, ...
    nnz(study.analysis.summary.Status == "processed"), 2);
verifyEqual(testCase, height(study.analysis.peakSummary), 2);
verifyEqual(testCase, study.populationStatus, "completed");
verifyEqual(testCase, study.population.specimenCount, 2);
end

function testStudySummary(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
study = mechanics.workflow.runTensileStudy( ...
    filename, localStudyConfig());
summary = mechanics.workflow.summarizeTensileStudy(study);
verifyEqual(testCase, summary.SpecimenCount, 2);
verifyEqual(testCase, summary.ProcessedSpecimenCount, 2);
verifyEqual(testCase, summary.PopulationStatus, "completed");
end

function testStudyExport(testCase)
filename = localCreateWorkbook();
cleanupFile = onCleanup(@() localDelete(filename)); %#ok<NASGU>
config = localStudyConfig();
config.export.enabled = true;
config.export.outputFolder = string(tempname);
cleanupFolder = onCleanup( ...
    @() localDeleteFolder(config.export.outputFolder)); %#ok<NASGU>
study = mechanics.workflow.runTensileStudy(filename, config);
verifyTrue(testCase, isfile(study.outputFiles.studySummary));
verifyTrue(testCase, isfile(study.outputFiles.datasetSummary));
verifyTrue(testCase, isfile(study.outputFiles.peakSummary));
verifyTrue(testCase, isfile(study.outputFiles.provenance));
verifyTrue(testCase, isfile(study.outputFiles.study));
verifyTrue(testCase, isfile(study.outputFiles.config));
end

function testExcludedSpecimenIsRemovedBeforeAnalysis(testCase)
filename = localCreateWorkbook(3);
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
config = localStudyConfig();
config.specimens.excludeIndices = 1;
config.specimens.exclusionReason = "different preload";
config.specimens.preloadForceOverrides = [0.5; 0.1; 0.1];
config.datasetAnalysis.processingConfig.preprocessing.zeroReference.method = ...
    "preload-threshold";
config.datasetAnalysis.processingConfig.preprocessing.zeroReference.preloadForce = 0.1;
config.datasetAnalysis.processingConfig.preprocessing.zeroReference.sustainedPoints = 2;
config.datasetAnalysis.quality.minimumObservations = 5;
config.population.config.bootstrap.enabled = false;
study = mechanics.workflow.runTensileStudy(filename, config);
verifyEqual(testCase, study.exclusion.indices, 1);
verifyEqual(testCase, study.exclusion.specimenIds, "sample-01");
verifyEqual(testCase, numel(study.dataset.specimens), 2);
verifyEqual(testCase, study.population.specimenCount, 2);
verifyEqual(testCase, string({study.analysis.records.specimenId})', ...
    ["sample-02"; "sample-03"]);
end

function testMissingWorkbookRejected(testCase)
verifyError(testCase, ...
    @() mechanics.workflow.runTensileStudy( ...
        "does-not-exist.xlsx", localStudyConfig()), ...
    "mechanics:workflow:StudyFileNotFound");
end

function config = localStudyConfig()
config = mechanics.config.tensileStudyConfig();
config.extraction.defaultInitialLength = 10;
config.datasetAnalysis.quality.minimumObservations = 3;
config.datasetAnalysis.segmentation.minimumObservations = 2;
config.datasetAnalysis.fitting.enabled = false;
config.population.config.minimumSpecimens = 2;
config.population.config.bootstrapSampleCount = 20;
config.export.enabled = false;
end

function filename = localCreateWorkbook(specimenCount)
if nargin == 0
    specimenCount = 2;
end
filename = string(tempname) + ".xlsx";
results = cell(specimenCount + 2, 4);
results(1,:) = {"", "Identificación de probeta", "h", "b"};
results(2,:) = {"", "", "mm", "mm"};
for index = 1:specimenCount
    results(index + 2,:) = { ...
        "Probeta " + index, "sample-" + compose("%02d", index), 2, 6};
end
writecell(results, filename, "Sheet", "Resultados", "Range", "A1");
for index = 1:specimenCount
    displacement = linspace(0, 3, 31)';
    preload = 0.1;
    if index == 1 && specimenCount == 3
        preload = 0.5;
    end
    force = preload + 2 .* displacement;
    localWriteSpecimen(filename, "Probeta " + index, displacement, force);
end
end

function localWriteSpecimen(filename, sheetName, displacement, force)
headers = {
    sheetName, sheetName;
    "Deformación", "Fuerza estándar";
    "mm", "N"
};
writecell(headers, filename, "Sheet", sheetName, "Range", "A1");
writematrix([displacement, force], filename, ...
    "Sheet", sheetName, "Range", "A4");
end

function localDelete(filename)
if isfile(filename)
    delete(filename);
end
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
