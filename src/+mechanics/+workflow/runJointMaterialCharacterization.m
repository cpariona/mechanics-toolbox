function result = runJointMaterialCharacterization(studies, modeNames, config)
%RUNJOINTMATERIALCHARACTERIZATION Run joint multi-mode material characterization.
arguments
    studies
    modeNames string
    config (1,1) struct = mechanics.config.jointMaterialCharacterizationConfig()
end

normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
selection = mechanics.workflow.selectJointModel(normalized, config);

result.modeNames = normalized.modeNames;
result.modeWeights = normalized.modeWeights;
result.specimens = normalized.specimens;
result.modeInputSummary = normalized.modeSummary;
result.candidates = selection.candidates;
result.candidateSummary = selection.candidateSummary;
result.selectedModelName = selection.selectedModelName;
result.selectedFit = selection.selectedFit;
result.modeSummary = selection.selectedFit.modeSummary;
result.specimenSummary = selection.selectedFit.specimenSummary;
result.selection = selection.selection;
result.config = config;
result.createdAt = datetime("now");
result.outputFiles = struct();

if isfield(config, "export") && isfield(config.export, "enabled") && ...
        logical(config.export.enabled)
    result.outputFiles = mechanics.io.exportJointMaterialCharacterization( ...
        result, string(config.export.outputFolder));
end
end
