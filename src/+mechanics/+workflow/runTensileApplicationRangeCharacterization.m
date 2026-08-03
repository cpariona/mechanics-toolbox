function result = runTensileApplicationRangeCharacterization( ...
    tensileStudy, config, compressionStudy)
%RUNTENSILEAPPLICATIONRANGECHARACTERIZATION Run the maintained add-on.
arguments
    tensileStudy (1,1) struct
    config (1,1) struct = ...
        mechanics.config.tensileApplicationRangeCharacterizationConfig()
    compressionStudy = []
end

normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);
candidates = mechanics.workflow.fitTensileApplicationRangeModels( ...
    normalized, config);
selection = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
sensitivity = mechanics.workflow.auditTensileApplicationRangeSensitivity( ...
    tensileStudy, config);

compressionValidation = struct();
if ~isempty(compressionStudy)
    if ~isstruct(compressionStudy) || ~isscalar(compressionStudy)
        error("mechanics:workflow:InvalidTensileApplicationRangeCompressionStudy", ...
            "Optional compression validation must be one completed study struct.");
    end
    compressionValidation = ...
        mechanics.workflow.validateTensileApplicationRangeCompression( ...
        selection, compressionStudy, config);
end

result.normalized = normalized;
result.candidates = candidates;
result.candidateSummary = selection.candidateSummary;
result.selectedModelName = selection.selectedModelName;
result.selectedFit = selection.selectedFit;
result.referenceProperties = selection.referenceProperties;
result.selection = selection.selection;
result.rangeSensitivity = sensitivity;
result.compressionValidation = compressionValidation;
result.hasCompressionValidation = ~isempty(fieldnames(compressionValidation));
result.config = config;
result.createdAt = datetime("now");
result.outputFiles = struct();

if isfield(config, "export") && isstruct(config.export) && ...
        isfield(config.export, "enabled") && logical(config.export.enabled)
    if ~isfield(config.export, "outputFolder") || ...
            strlength(string(config.export.outputFolder)) == 0
        error("mechanics:workflow:MissingTensileApplicationRangeOutputFolder", ...
            "Enabled export requires config.export.outputFolder.");
    end
    result.outputFiles = ...
        mechanics.io.exportTensileApplicationRangeCharacterization( ...
        result, string(config.export.outputFolder));
end
end
