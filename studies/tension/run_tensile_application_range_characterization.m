%% 0. INITIALIZATION AND COMPLETED STUDY FILES
% Executable driver for tensile application-range characterization.
% This driver consumes completed study MAT files and does not reprocess raw data.

restoredefaultpath
clear classes
clear functions
clear
clc
close all

repositoryFolder = 'D:\Escritorio\mechanics-toolbox';
cd(repositoryFolder)
startup

tensileStudyFile = fullfile(repositoryFolder, "results", ...
    "real-tensile-study", "tensile_study.mat");
compressionStudyFile = fullfile(repositoryFolder, "results", ...
    "real-compression-study", "compression_study.mat");
outputFolder = fullfile(repositoryFolder, "results", ...
    "tensile-application-range-characterization");

%% 1. LOAD COMPLETED STUDIES
tensileStudy = localLoadStudy(tensileStudyFile, ...
    ["tensileStudy"; "study"]);

useCompressionValidation = isfile(compressionStudyFile);
compressionStudy = [];
if useCompressionValidation
    compressionStudy = localLoadStudy(compressionStudyFile, ...
        ["compressionStudy"; "study"]);
end

%% 2. CHARACTERIZATION CONFIGURATION
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.fitRange = [0, 0.50];
config.candidateModelNames = [ ...
    "neo-hookean"; ...
    "mooney-rivlin"; ...
    "yeoh-second-order"; ...
    "yeoh"];
config.fitting.numberOfStarts = 8;
config.fitting.randomSeed = 1;
config.fitting.maxIterations = 3000;
config.fitting.maxFunctionEvaluations = 10000;
config.selection.requireConvergence = true;
config.selection.practicalObjectiveTolerance = 0.02;
config.selection.tieBreakOrder = config.candidateModelNames;
config.rangeSensitivity.maximumDeformations = [0.30; 0.40; 0.50];
config.compressionValidation.minimumSpecimens = 1;
config.export.enabled = true;
config.export.outputFolder = outputFolder;

%% 3. RUN AND REVIEW
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config, compressionStudy);

disp(result.candidateSummary)
disp(result.selectedModelName)
disp(table(string(result.selectedFit.parameterNames(:)), ...
    result.selectedFit.parameters(:), ...
    'VariableNames', {'Parameter','Estimate'}))
disp(table(string(result.referenceProperties.names(:)), ...
    result.referenceProperties.values(:), ...
    'VariableNames', {'Property','Estimate'}))
disp(result.selectedFit.specimenSummary)
disp(result.rangeSensitivity.scenarioSummary)
if result.hasCompressionValidation
    disp(result.compressionValidation.specimenSummary)
end
disp(result.outputFiles)

%% LOCAL DRIVER UTILITY
function study = localLoadStudy(filePath, preferredNames)
if ~isfile(filePath)
    error("mechanics:driver:MissingCompletedStudy", ...
        "Completed study MAT file does not exist: %s", filePath);
end
loaded = load(filePath);
fields = string(fieldnames(loaded));
match = preferredNames(ismember(preferredNames, fields));
if ~isempty(match)
    study = loaded.(char(match(1)));
elseif numel(fields) == 1
    study = loaded.(char(fields(1)));
else
    error("mechanics:driver:AmbiguousCompletedStudyFile", ...
        "MAT file %s does not contain a unique recognized study variable.", filePath);
end
if ~isstruct(study) || ~isfield(study, "analysis") || ...
        ~isfield(study.analysis, "records")
    error("mechanics:driver:InvalidCompletedStudyResult", ...
        "MAT file %s does not contain a recognized completed study result.", ...
        filePath);
end
end
