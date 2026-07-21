function analysis = runFitDiagnostics( ...
        modelName, deformation, measuredStress, context, fitConfig, config)
%RUNFITDIAGNOSTICS Run fitting and all configured reliability diagnostics.
arguments
    modelName (1,1) string
    deformation {mustBeNumeric, mustBeReal}
    measuredStress {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
    fitConfig (1,1) struct = mechanics.config.fittingConfig()
    config (1,1) struct = mechanics.config.fitDiagnosticsWorkflowConfig()
end

fitResult = mechanics.fitting.fitModel( ...
    modelName, deformation, measuredStress, context, fitConfig);

uncertainty = struct();
identifiability = struct();
windowStability = struct();
residualDiagnostics = struct();
diagnosticErrors = localEmptyErrorTable();

if config.runBootstrap
    [uncertainty, diagnosticErrors] = localRunOptional( ...
        @() mechanics.fitting.bootstrapFitUncertainty( ...
            fitResult, config.bootstrapConfig), ...
        "Bootstrap", diagnosticErrors, ...
        config.continueOnOptionalDiagnosticError);
end

if config.runIdentifiability && ~isempty(fieldnames(uncertainty))
    [identifiability, diagnosticErrors] = localRunOptional( ...
        @() mechanics.fitting.analyzeFitIdentifiability( ...
            fitResult, uncertainty, config.identifiabilityConfig), ...
        "Identifiability", diagnosticErrors, ...
        config.continueOnOptionalDiagnosticError);
end

if config.runWindowStability
    [windowStability, diagnosticErrors] = localRunOptional( ...
        @() mechanics.fitting.analyzeFitWindowStability( ...
            modelName, deformation, measuredStress, context, ...
            fitConfig, config.windowStabilityConfig), ...
        "WindowStability", diagnosticErrors, ...
        config.continueOnOptionalDiagnosticError);
end

if config.runResidualDiagnostics
    [residualDiagnostics, diagnosticErrors] = localRunOptional( ...
        @() mechanics.fitting.analyzeFitResiduals( ...
            fitResult, config.residualDiagnosticsConfig), ...
        "Residuals", diagnosticErrors, ...
        config.continueOnOptionalDiagnosticError);
end

reliability = mechanics.fitting.assessFitReliability( ...
    fitResult, uncertainty, identifiability, windowStability, ...
    residualDiagnostics, config.reliabilityConfig);

analysis.modelName = string(modelName);
analysis.createdAt = datetime("now");
analysis.fitResult = fitResult;
analysis.uncertainty = uncertainty;
analysis.identifiability = identifiability;
analysis.windowStability = windowStability;
analysis.residualDiagnostics = residualDiagnostics;
analysis.reliability = reliability;
analysis.diagnosticErrors = diagnosticErrors;
analysis.context = context;
analysis.fitConfig = fitConfig;
analysis.config = config;
end

function [result, errors] = localRunOptional(operation, name, errors, continueOnError)
try
    result = operation();
catch ME
    if ~continueOnError
        rethrow(ME);
    end
    result = struct();
    newRow = table(string(name), string(ME.identifier), string(ME.message), ...
        'VariableNames', {'Diagnostic','ErrorIdentifier','ErrorMessage'});
    errors = [errors; newRow]; %#ok<AGROW>
end
end

function errors = localEmptyErrorTable()
errors = table(strings(0,1), strings(0,1), strings(0,1), ...
    'VariableNames', {'Diagnostic','ErrorIdentifier','ErrorMessage'});
end