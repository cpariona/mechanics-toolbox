function config = fitDiagnosticsWorkflowConfig()
%FITDIAGNOSTICSWORKFLOWCONFIG Configure integrated fit diagnostics.
config.runBootstrap = true;
config.runIdentifiability = true;
config.runWindowStability = true;
config.runResidualDiagnostics = true;
config.continueOnOptionalDiagnosticError = true;
config.bootstrapConfig = mechanics.config.fitUncertaintyConfig();
config.identifiabilityConfig = mechanics.config.fitIdentifiabilityConfig();
config.windowStabilityConfig = mechanics.config.fitWindowStabilityConfig();
config.residualDiagnosticsConfig = mechanics.config.residualDiagnosticsConfig();
config.reliabilityConfig = mechanics.config.fitReliabilityConfig();
end