function config = batchModelComparisonConfig()
%BATCHMODELCOMPARISONCONFIG Configure specimen-level model comparison.
config.continueOnSpecimenError = true;
config.minimumSuccessfulSpecimens = 1;
config.requireSelectedModel = false;
config.includeGroupSummary = true;
config.comparisonConfig = mechanics.config.modelComparisonWorkflowConfig();

% Batch comparison is primarily used to select a model and summarize
% parameters across specimens. Expensive optional diagnostics are disabled by
% default so that a diagnostic failure does not invalidate an otherwise valid
% specimen fit. Callers may explicitly enable any diagnostic when required.
diagnostics = config.comparisonConfig.fitDiagnosticsConfig;
diagnostics.runBootstrap = false;
diagnostics.runIdentifiability = false;
diagnostics.runWindowStability = false;
diagnostics.runResidualDiagnostics = false;
config.comparisonConfig.fitDiagnosticsConfig = diagnostics;
end
