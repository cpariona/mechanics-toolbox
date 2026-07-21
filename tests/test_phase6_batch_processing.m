function tests = test_phase6_batch_processing
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testManifestDefaults(testCase)
manifest = table( ...
    "sample.csv", "sample-01", 10, 2, ...
    'VariableNames', {'File','SpecimenId','InitialLength','InitialArea'});

manifest = mechanics.workflow.validateBatchManifest(manifest);

verifyTrue(testCase, manifest.Include);
verifyEqual(testCase, manifest.Sheet, 1);
verifyEqual(testCase, manifest.ForceScale, 1);
verifyEqual(testCase, manifest.TestType, "tension");
end

function testManifestIncludeTextValues(testCase)
manifest = table( ...
    ["one.csv"; "two.csv"], ...
    ["one"; "two"], ...
    [10; 10], ...
    [2; 2], ...
    {"true"; "false"}, ...
    'VariableNames', { ...
        'File','SpecimenId','InitialLength','InitialArea','Include'});

manifest = mechanics.workflow.validateBatchManifest(manifest);

verifyEqual(testCase, manifest.Include, [true; false]);
end

function testMissingManifestColumnRejected(testCase)
manifest = table("sample.csv", "sample-01", 10, ...
    'VariableNames', {'File','SpecimenId','InitialLength'});

verifyError(testCase, ...
    @() mechanics.workflow.validateBatchManifest(manifest), ...
    "mechanics:workflow:InvalidManifest");
end

function testTwoSpecimensAreProcessed(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() localRemoveFolder(folder));

fileOne = fullfile(folder, "one.csv");
fileTwo = fullfile(folder, "two.csv");
localWriteCurve(fileOne, 1);
localWriteCurve(fileTwo, 2);

manifest = table( ...
    [string(fileOne); string(fileTwo)], ...
    ["one"; "two"], ...
    [10; 10], ...
    [2; 2], ...
    'VariableNames', {'File','SpecimenId','InitialLength','InitialArea'});

config = mechanics.config.batchProcessingConfig();
batch = mechanics.workflow.processBatchManifest(manifest, config);

verifyEqual(testCase, batch.summary.Status, ...
    ["processed"; "processed"]);
verifyEqual(testCase, batch.summary.ObservationCount, [5; 5]);
verifyEqual(testCase, batch.summary.MaximumStress, [2; 4], ...
    "AbsTol", 1e-12);
end

function testFailureIsRecorded(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() localRemoveFolder(folder));

validFile = fullfile(folder, "valid.csv");
localWriteCurve(validFile, 1);

manifest = table( ...
    [string(validFile); fullfile(folder, "missing.csv")], ...
    ["valid"; "missing"], ...
    [10; 10], ...
    [2; 2], ...
    'VariableNames', {'File','SpecimenId','InitialLength','InitialArea'});

config = mechanics.config.batchProcessingConfig();
config.continueOnError = true;

batch = mechanics.workflow.processBatchManifest(manifest, config);

verifyEqual(testCase, batch.summary.Status, ...
    ["processed"; "failed"]);
verifyEqual(testCase, batch.summary.ErrorIdentifier(2), ...
    "mechanics:io:FileNotFound");
end

function testSkippedRow(testCase)
manifest = table( ...
    "missing.csv", "skip-me", 10, 2, false, ...
    'VariableNames', { ...
        'File','SpecimenId','InitialLength','InitialArea','Include'});

batch = mechanics.workflow.processBatchManifest( ...
    manifest, mechanics.config.batchProcessingConfig());

verifyEqual(testCase, batch.summary.Status, "skipped");
end

function testBatchExport(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() localRemoveFolder(folder));

batch.summary = table("sample", "processed", ...
    'VariableNames', {'SpecimenId','Status'});

outputFiles = mechanics.io.exportBatchSummary(batch, folder);

verifyTrue(testCase, isfile(outputFiles.summary));
verifyTrue(testCase, isfile(outputFiles.batch));
end

function localWriteCurve(filename, forceMultiplier)
data = table( ...
    (0:4)', ...
    forceMultiplier .* (0:4)', ...
    'VariableNames', {'Displacement', 'Force'});
writetable(data, filename);
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
