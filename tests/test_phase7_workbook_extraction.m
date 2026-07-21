function tests = test_phase7_workbook_extraction
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testZwickWorkbookIsDetected(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename));

config = mechanics.config.workbookExtractionConfig();

verifyTrue(testCase, ...
    mechanics.extraction.detectZwickD412Workbook(filename, config));
end

function testZwickSpecimensAndGeometryAreExtracted(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename));

config = mechanics.config.workbookExtractionConfig();
config.defaultInitialLength = 25;

dataset = mechanics.extraction.extractWorkbook(filename, config);

verifyEqual(testCase, dataset.extractor.name, "zwick-d412");
verifyEqual(testCase, numel(dataset.specimens), 2);

verifyEqual(testCase, dataset.specimens(1).id, "sample-01");
verifyEqual(testCase, dataset.specimens(1).sheetName, "Probeta 21");
verifyEqual(testCase, dataset.specimens(1).geometry.thickness, 2);
verifyEqual(testCase, dataset.specimens(1).geometry.width, 6);
verifyEqual(testCase, dataset.specimens(1).geometry.initialArea, 12);
verifyEqual(testCase, dataset.specimens(1).geometry.initialLength, 25);

verifyEqual(testCase, dataset.specimens(1).raw.displacement, ...
    [0; 1; 2], "AbsTol", 1e-12);
verifyEqual(testCase, dataset.specimens(1).raw.force, ...
    [0.5; 1.5; 2.5], "AbsTol", 1e-12);
verifyEqual(testCase, dataset.specimens(1).source.displacementUnit, "mm");
verifyEqual(testCase, dataset.specimens(1).source.forceUnit, "N");
end

function testExtractedDatasetCanBeProcessed(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename));

config = mechanics.config.workbookExtractionConfig();
config.defaultInitialLength = 10;

dataset = mechanics.extraction.extractWorkbook(filename, config);
processed = mechanics.workflow.processExtractedDataset( ...
    dataset, mechanics.config.tensionConfig());

verifyEqual(testCase, ...
    processed.specimens(1).processed.strain, ...
    [0; 0.1; 0.2], "AbsTol", 1e-12);
verifyEqual(testCase, ...
    processed.specimens(1).processed.stress, ...
    [0; 1/12; 2/12], "AbsTol", 1e-12);
verifyEqual(testCase, height(processed.summary), 2);
end

function testMissingInitialLengthIsRejected(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename));

dataset = mechanics.extraction.extractWorkbook( ...
    filename, mechanics.config.workbookExtractionConfig());

verifyError(testCase, @() mechanics.workflow.processExtractedDataset( ...
    dataset, mechanics.config.tensionConfig()), ...
    "mechanics:workflow:MissingInitialLength");
end

function testCustomExtractorIsSupported(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename));

config = mechanics.config.workbookExtractionConfig();
config.customExtractor = @localCustomExtractor;

dataset = mechanics.extraction.extractWorkbook(filename, config);

verifyEqual(testCase, dataset.specimens.id, "custom");
verifyEqual(testCase, dataset.specimens.raw.force, [1; 2]);
end

function dataset = localCustomExtractor(filename, ~)
specimen.id = "custom";
specimen.raw.force = [1; 2];
specimen.raw.displacement = [0; 1];
specimen.geometry.initialLength = 1;
specimen.geometry.initialArea = 1;
specimen.source.filename = filename;

dataset.source.filename = filename;
dataset.specimens = specimen;
end

function filename = localCreateWorkbook()
filename = string(tempname) + ".xlsx";

results = {
    "", "Identificación de probeta", "h", "b";
    "", "", "mm", "mm";
    "Probeta 21", "sample-01", 2, 6;
    "Probeta 22", "sample-02", 2.1, 6
};
writecell(results, filename, "Sheet", "Resultados", "Range", "A1");

specimen21 = {
    "Probeta 21", "Probeta 21";
    "Deformación", "Fuerza estándar";
    "mm", "N";
    0, 0.5;
    1, 1.5;
    2, 2.5
};
writecell(specimen21, filename, "Sheet", "Probeta 21", "Range", "A1");

specimen22 = {
    "Probeta 22", "Probeta 22";
    "Deformación", "Fuerza estándar";
    "mm", "N";
    0, 0.6;
    1, 1.6;
    2, 2.6
};
writecell(specimen22, filename, "Sheet", "Probeta 22", "Range", "A1");
end

function localDelete(filename)
if isfile(filename)
    delete(filename);
end
end
