function study = fitAcrossWindows(modelNames, deformation, measuredStress, context, fitConfig, selectionConfig)
%FITACROSSWINDOWS Fit registered models over nested deformation windows.
arguments
    modelNames string
    deformation {mustBeNumeric, mustBeReal}
    measuredStress {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
    fitConfig (1,1) struct = mechanics.config.fittingConfig()
    selectionConfig (1,1) struct = mechanics.config.modelSelectionConfig()
end

if numel(deformation) ~= numel(measuredStress)
    error("mechanics:fitting:SizeMismatch", ...
        "Deformation and stress must contain the same number of values.");
end

x = deformation(:);
y = measuredStress(:);
valid = isfinite(x) & isfinite(y);
x = x(valid);
y = y(valid);

if numel(x) < selectionConfig.minimumObservations
    error("mechanics:fitting:InsufficientData", ...
        "At least %d finite observations are required.", ...
        selectionConfig.minimumObservations);
end

[x, order] = sort(x, "ascend");
y = y(order);

fractions = selectionConfig.windowFractions(:);
if isempty(fractions) || any(~isfinite(fractions)) || ...
        any(fractions <= 0) || any(fractions > 1)
    error("mechanics:fitting:InvalidWindowFractions", ...
        "Window fractions must be finite values in the interval (0, 1].");
end
fractions = unique(fractions, "sorted");

xMin = x(1);
xMax = x(end);
xRange = xMax - xMin;
if xRange <= 0
    error("mechanics:fitting:InvalidDeformationRange", ...
        "Deformation values must span a nonzero range.");
end

modelNames = modelNames(:);
records = struct( ...
    "modelName", {}, ...
    "windowFraction", {}, ...
    "maximumDeformation", {}, ...
    "observationCount", {}, ...
    "fitResult", {}, ...
    "succeeded", {}, ...
    "errorIdentifier", {}, ...
    "errorMessage", {});

recordIndex = 0;
for iModel = 1:numel(modelNames)
    for iWindow = 1:numel(fractions)
        fraction = fractions(iWindow);
        threshold = xMin + fraction .* xRange;
        mask = x <= threshold;

        if nnz(mask) < selectionConfig.minimumObservations
            continue;
        end

        recordIndex = recordIndex + 1;
        records(recordIndex).modelName = modelNames(iModel);
        records(recordIndex).windowFraction = fraction;
        records(recordIndex).maximumDeformation = max(x(mask));
        records(recordIndex).observationCount = nnz(mask);

        try
            result = mechanics.fitting.fitModel( ...
                modelNames(iModel), x(mask), y(mask), context, fitConfig);
            records(recordIndex).fitResult = result;
            records(recordIndex).succeeded = true;
            records(recordIndex).errorIdentifier = "";
            records(recordIndex).errorMessage = "";
        catch ME
            records(recordIndex).fitResult = struct();
            records(recordIndex).succeeded = false;
            records(recordIndex).errorIdentifier = string(ME.identifier);
            records(recordIndex).errorMessage = string(ME.message);
        end
    end
end

if isempty(records)
    error("mechanics:fitting:NoValidWindows", ...
        "No window contained enough observations for fitting.");
end

study.modelNames = modelNames;
study.windowFractions = fractions;
study.records = records;
study.deformation = x;
study.measuredStress = y;
study.context = context;
study.fitConfig = fitConfig;
study.selectionConfig = selectionConfig;
study.summary = mechanics.fitting.summarizeWindowStability(study);
study.selection = mechanics.fitting.selectBestModel( ...
    study.summary, selectionConfig);
end
