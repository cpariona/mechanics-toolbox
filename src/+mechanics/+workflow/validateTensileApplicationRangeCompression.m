function validation = validateTensileApplicationRangeCompression(selection, compressionStudy, config)
%VALIDATETENSILEAPPLICATIONRANGECOMPRESSION Predict compression without refitting.
arguments
    selection (1,1) struct
    compressionStudy (1,1) struct
    config (1,1) struct = ...
        mechanics.config.tensileApplicationRangeCharacterizationConfig()
end

localValidateSelection(selection);
jointConfig = mechanics.config.jointMaterialCharacterizationConfig();
jointConfig.modeNames = "compression";
jointConfig.modeWeights = 1;
jointConfig.requireFiniteObservations = config.requireFiniteObservations;
jointConfig.requireMatchingStressUnits = config.requireMatchingStressUnits;
jointConfig.requireMatchingStrainUnits = config.requireMatchingStrainUnits;
jointConfig.signTolerance = config.signTolerance;
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    compressionStudy, "compression", jointConfig);

minimumSpecimens = localMinimumSpecimens(config);
if normalized.specimenCount < minimumSpecimens
    error("mechanics:workflow:InsufficientCompressionValidationSpecimens", ...
        "Compression validation retained %d specimens; at least %d are required.", ...
        normalized.specimenCount, minimumSpecimens);
end

modelName = selection.selectedModelName;
parameters = selection.selectedFit.parameters;
specimens = normalized.specimens;
specimenId = strings(numel(specimens), 1);
observationCount = zeros(numel(specimens), 1);
rmse = zeros(numel(specimens), 1);
normalizedRMSE = zeros(numel(specimens), 1);
maximumAbsoluteError = zeros(numel(specimens), 1);

for index = 1:numel(specimens)
    prediction = mechanics.models.evaluateModel( ...
        modelName, specimens(index).Deformation, parameters, specimens(index).Context);
    residual = specimens(index).MeasuredStress - prediction;
    scale = max(specimens(index).MeasuredStress) - min(specimens(index).MeasuredStress);
    if ~isfinite(scale) || scale < config.normalization.minimumScale
        scale = max(abs(specimens(index).MeasuredStress));
    end
    scale = max(scale, config.normalization.minimumScale);
    specimens(index).PredictedStress = prediction;
    specimens(index).Residuals = residual;
    specimens(index).NormalizationScale = scale;
    specimenId(index) = specimens(index).SpecimenId;
    observationCount(index) = specimens(index).ObservationCount;
    rmse(index) = sqrt(mean(residual.^2));
    normalizedRMSE(index) = rmse(index) / scale;
    maximumAbsoluteError(index) = max(abs(residual));
end

specimenSummary = table(specimenId, observationCount, rmse, ...
    normalizedRMSE, maximumAbsoluteError, ...
    'VariableNames', {'SpecimenId','ObservationCount','RMSE', ...
    'NormalizedRMSE','MaximumAbsoluteError'});

validation.modelName = modelName;
validation.parameters = reshape(double(parameters), 1, []);
validation.refitPerformed = false;
validation.normalizedCompression = normalized;
validation.specimens = specimens;
validation.specimenSummary = specimenSummary;
validation.meanRMSE = mean(rmse);
validation.meanNormalizedRMSE = mean(normalizedRMSE);
validation.config = config;
validation.createdAt = datetime("now");
end

function localValidateSelection(selection)
required = ["selectedModelName", "selectedFit", "referenceProperties"];
if ~all(isfield(selection, required)) || ...
        ~isstruct(selection.selectedFit) || ...
        ~isfield(selection.selectedFit, "parameters")
    error("mechanics:workflow:InvalidTensileApplicationRangeSelection", ...
        "Provide a completed D3 tensile application-range selection result.");
end
end

function minimumSpecimens = localMinimumSpecimens(config)
if ~isfield(config, "compressionValidation") || ...
        ~isstruct(config.compressionValidation) || ...
        ~isfield(config.compressionValidation, "minimumSpecimens")
    error("mechanics:workflow:MissingCompressionValidationConfig", ...
        "Configure compressionValidation.minimumSpecimens.");
end
minimumSpecimens = double(config.compressionValidation.minimumSpecimens);
if ~isscalar(minimumSpecimens) || ~isfinite(minimumSpecimens) || ...
        minimumSpecimens < 1 || minimumSpecimens ~= round(minimumSpecimens)
    error("mechanics:workflow:InvalidCompressionValidationMinimumSpecimens", ...
        "compressionValidation.minimumSpecimens must be a positive integer.");
end
end
