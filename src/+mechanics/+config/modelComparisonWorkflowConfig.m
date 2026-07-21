function config = modelComparisonWorkflowConfig()
%MODELCOMPARISONWORKFLOWCONFIG Configure reliability-aware model comparison.
config.selectionCriterion = "aicc";
config.allowedReliabilityStatuses = ["reliable", "caution"];
config.continueOnModelError = true;
config.requireEligibleModel = true;
config.fitDiagnosticsConfig = mechanics.config.fitDiagnosticsWorkflowConfig();
end
