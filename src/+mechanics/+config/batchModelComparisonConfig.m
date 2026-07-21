function config = batchModelComparisonConfig()
%BATCHMODELCOMPARISONCONFIG Configure specimen-level model comparison.
config.continueOnSpecimenError = true;
config.minimumSuccessfulSpecimens = 1;
config.requireSelectedModel = false;
config.includeGroupSummary = true;
config.comparisonConfig = mechanics.config.modelComparisonWorkflowConfig();
end
