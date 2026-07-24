function tests = test_tensile_study_input_contracts
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testPreExtractedDatasetIsAccepted(testCase)
dataset = localDataset("S1");
config = mechanics.config.tensileStudyConfig();
[normalized, info] = mechanics.workflow.normalizeTensileStudyInput(dataset, config);
verifyEqual(testCase, info.type, "dataset");
verifyEqual(testCase, info.specimenCount, 1);
verifyEqual(testCase, normalized.specimens.id, "S1");
end

function testWorkbookAndFileListConvergeToDataset(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = [fullfile(folder,"A.xlsx"); fullfile(folder,"B.xlsx")];
for index = 1:numel(files)
    fclose(fopen(files(index),"w"));
end
config = mechanics.config.tensileStudyConfig();
config.extraction.customExtractor = @localCustomExtractor;

[singleDataset, singleInfo] = mechanics.workflow.normalizeTensileStudyInput( ...
    files(1), config);
[listDataset, listInfo] = mechanics.workflow.normalizeTensileStudyInput( ...
    files, config);

verifyEqual(testCase, singleInfo.type, "workbook");
verifyEqual(testCase, numel(singleDataset.specimens), 1);
verifyEqual(testCase, listInfo.type, "file-list");
verifyEqual(testCase, numel(listDataset.specimens), 2);
verifyEqual(testCase, string({listDataset.specimens.id})', ["A";"B"]);
end

function testManifestConvergesToDataset(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
filename = fullfile(folder,"specimen.csv");
writetable(table((0:4)',(0:4)', ...
    'VariableNames',{'Force','Displacement'}), filename);
manifest = table(filename,"M1",10,2,true,1,"Force","Displacement", ...
    'VariableNames',{'File','SpecimenId','InitialLength','InitialArea', ...
    'Include','Sheet','ForceColumn','DisplacementColumn'});
config = mechanics.config.tensileStudyConfig();
config.input.type = "manifest";
[dataset, info] = mechanics.workflow.normalizeTensileStudyInput(manifest, config);
verifyEqual(testCase, info.type, "manifest");
verifyEqual(testCase, dataset.specimens.id, "M1");
verifyEqual(testCase, dataset.specimens.geometry.initialLength, 10);
verifyEqual(testCase, dataset.specimens.geometry.initialArea, 2);
end

function testRunTensileStudyPreservesDownstreamContract(testCase)
dataset = localDataset("S1");
config = mechanics.config.tensileStudyConfig();
config.datasetAnalysis.segmentation.minimumObservations = 5;
config.datasetAnalysis.quality.rejectFailedQuality = false;
config.datasetAnalysis.fitting.enabled = false;
config.peakAnalysis.enabled = false;
config.population.enabled = false;
config.export.enabled = false;
study = mechanics.workflow.runTensileStudy(dataset, config);
required = {'dataset','analysis','population','populationStatus','provenance', ...
    'config','createdAt','input','sourceFiles'};
verifyTrue(testCase, all(isfield(study,required)));
verifyEqual(testCase, study.input.type, "dataset");
verifyEqual(testCase, height(study.analysis.summary), 1);
end

function dataset = localDataset(specimenId)
strain = linspace(0,0.5,30)';
dataset.specimens.id = string(specimenId);
dataset.specimens.raw.force = 2 .* strain + 0.2 .* strain.^2;
dataset.specimens.raw.displacement = 10 .* strain;
dataset.specimens.geometry.initialLength = 10;
dataset.specimens.geometry.initialArea = 1;
dataset.specimens.source.filename = "";
end

function dataset = localCustomExtractor(filename, ~)
[~,name] = fileparts(filename);
dataset = localDataset(string(name));
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder,'s');
end
end
