%% 0. INITIALIZATION AND COMPLETED STUDY FILES
% Executable driver for joint tension-compression material characterization.
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
    "joint-material-characterization");

%% 1. LOAD COMPLETED STUDIES
% Each MAT file must contain exactly one completed study result or a variable
% named study, tensileStudy, or compressionStudy.
tensileStudy = localLoadStudy(tensileStudyFile, ...
    ["tensileStudy"; "study"]);
compressionStudy = localLoadStudy(compressionStudyFile, ...
    ["compressionStudy"; "study"]);

studies = {tensileStudy, compressionStudy};
modeNames = ["tension"; "compression"];

%% 2. JOINT CHARACTERIZATION CONFIGURATION
config = mechanics.config.jointMaterialCharacterizationConfig();
config.candidateModelNames = [ ...
    "neo-hookean"; ...
    "mooney-rivlin"; ...
    "yeoh-second-order"; ...
    "yeoh"];
config.modeNames = modeNames;
config.modeWeights = [1; 1];
config.specimenWeighting = "equal";
config.normalization.method = "response-range";
config.fitting.numberOfStarts = 8;
config.fitting.randomSeed = 1;
config.fitting.maxIterations = 3000;
config.fitting.maxFunctionEvaluations = 10000;
config.selection.requireConvergence = true;
config.selection.practicalObjectiveTolerance = 0.02;
config.selection.tieBreakOrder = config.candidateModelNames;
config.export.enabled = true;
config.export.outputFolder = outputFolder;

%% 3. RUN AND REVIEW
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);

disp(result.candidateSummary)
disp(result.selectedModelName)
disp(table(string(result.selectedFit.parameterNames(:)), ...
    result.selectedFit.parameters(:), ...
    'VariableNames', {'Parameter','Estimate'}))
disp(result.modeSummary)
disp(result.specimenSummary)
disp(result.outputFiles)

%% 4. OPTIONAL ROBUSTNESS AUDIT
runRobustnessAudit = true;
if runRobustnessAudit
    auditConfig = mechanics.config.jointCharacterizationAuditConfig();
    auditInput.modeNames = result.modeNames;
    auditInput.specimens = result.specimens;
    auditInput.specimenCount = numel(result.specimens);
    auditInput.observationCount = sum([result.specimens.ObservationCount]);
    robustnessAudit = ...
        mechanics.workflow.auditJointMaterialCharacterization( ...
        auditInput, config, auditConfig);
    disp(robustnessAudit.scenarioSummary)
end

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
if ~isstruct(study) || ~isfield(study, "populationStatus") || ...
        string(study.populationStatus) ~= "completed"
    error("mechanics:driver:IncompleteStudyResult", ...
        "MAT file %s does not contain a completed study result.", filePath);
end
end
