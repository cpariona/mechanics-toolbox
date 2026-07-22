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
cleanup = onCleanup(@() localDelete(filename));

study = mechanics.workflow.runTensileStudy( ...
    filename, localStudyConfig());

verifyEqual(testCase, height(study.analysis.summary), 2);
verifyEqual(testCase, ...
    nnz(study.analysis.summary.Status == "processed"), 2);
verifyEqual(testCase, ...
    height(study.analysis.fractureSummary), 2);
verifyEqual(testCase, study.populationStatus, "completed");
verifyEqual(testCase, study.population.specimenCount, 2);
end

function testStudySummary(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename));

study = mechanics.workflow.runTensileStudy( ...
    filename, localStudyConfig());

summary = mechanics.workflow.summarizeTensileStudy(study);

verifyEqual(testCase, summary.SpecimenCount, 2);
verifyEqual(testCase, summary.ProcessedSpecimenCount, 2);
verifyEqual(testCase, summary.PopulationStatus, "completed");
end

function testStudyExport(testCase)
filename = localCreateWorkbook();
cleanupFile = onCleanup(@() localDelete(filename));

config = localStudyConfig();
config.export.enabled = true;
config.export.outputFolder = string(tempname);
cleanupFolder = onCleanup( ...
    @() localDeleteFolder(config.export.outputFolder));

study = mechanics.workflow.runTensileStudy(filename, config);

verifyTrue(testCase, isfile(study.outputFiles.studySummary));
verifyTrue(testCase, isfile(study.outputFiles.datasetSummary));
verifyTrue(testCase, isfile(study.outputFiles.fractureSummary));
verifyTrue(testCase, isfile(study.outputFiles.provenance));
verifyTrue(testCase, isfile(study.outputFiles.study));
verifyTrue(testCase, isfile(study.outputFiles.config));
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

function filename = localCreateWorkbook()
filename = string(tempname) + ".xlsx";

results = {
    "", "Identificación de probeta", "h", "b";
    "", "", "mm", "mm";
    "Probeta 21", "sample-01", 2, 6;
    "Probeta 22", "sample-02", 2, 6
};
writecell(results, filename, ...
    "Sheet", "Resultados", "Range", "A1");

localWriteSpecimen(filename, "Probeta 21", ...
    [0;1;2;3;4;5], [0;1;2;3;1;0]);
localWriteSpecimen(filename, "Probeta 22", ...
    [0;1;2;3;4;5], [0;1.1;2.1;3.1;1;0]);
end

function localWriteSpecimen(filename, sheetName, displacement, force)
headers = {
    sheetName, sheetName;
    "Deformación", "Fuerza estándar";
    "mm", "N"
};
writecell(headers, filename, ...
    "Sheet", sheetName, "Range", "A1");
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
