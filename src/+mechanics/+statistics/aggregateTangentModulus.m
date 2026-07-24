function aggregate = aggregateTangentModulus(specimens, config)
%AGGREGATETANGENTMODULUS Interpolate tangent-modulus curves on a common grid.
arguments
    specimens struct
    config (1,1) struct = mechanics.config.populationAnalysisConfig()
end

specimens = specimens(:);
if numel(specimens) < config.minimumSpecimens
    error("mechanics:statistics:InsufficientSpecimens", ...
        "At least %d processed specimens are required.", ...
        config.minimumSpecimens);
end

curveCount = numel(specimens);
preparedStrain = cell(curveCount, 1);
preparedModulus = cell(curveCount, 1);
minimumStrain = nan(curveCount, 1);
maximumStrain = nan(curveCount, 1);
specimenIds = strings(curveCount, 1);

for index = 1:curveCount
    specimen = specimens(index);
    if ~isfield(specimen, "analysis") || ...
            ~isfield(specimen.analysis, "tangentModulus")
        error("mechanics:statistics:MissingTangentModulus", ...
            "Every specimen must contain tangent-modulus analysis.");
    end

    tangent = specimen.analysis.tangentModulus;
    if ~isfield(tangent, "strain") || ...
            ~isfield(tangent, "tangentModulusForPlot")
        error("mechanics:statistics:MissingTangentModulusCurve", ...
            ["Every tangent-modulus result must contain strain and " ...
             "tangentModulusForPlot."]);
    end

    [strain, modulus] = localPrepareCurve( ...
        tangent.strain, tangent.tangentModulusForPlot);
    preparedStrain{index} = strain;
    preparedModulus{index} = modulus;
    minimumStrain(index) = min(strain);
    maximumStrain(index) = max(strain);

    if isfield(specimen, "id")
        specimenIds(index) = string(specimen.id);
    else
        specimenIds(index) = "specimen-" + index;
    end
end

minimumSpecimens = round(config.minimumSpecimens);
strainLimits = localSupportedStrainRange( ...
    minimumStrain, maximumStrain, minimumSpecimens, config);

gridPointCount = round(config.strainGridPointCount);
if ~isscalar(gridPointCount) || gridPointCount < 2
    error("mechanics:statistics:InvalidGridPointCount", ...
        "strainGridPointCount must be at least 2.");
end

strainGrid = linspace(strainLimits(1), strainLimits(2), gridPointCount)';
modulusMatrix = nan(gridPointCount, curveCount);
for index = 1:curveCount
    supported = strainGrid >= minimumStrain(index) & ...
        strainGrid <= maximumStrain(index);
    modulusMatrix(supported, index) = interp1( ...
        preparedStrain{index}, preparedModulus{index}, ...
        strainGrid(supported), "linear");
end

specimenCountByPoint = sum(isfinite(modulusMatrix), 2);
if any(specimenCountByPoint < minimumSpecimens)
    error("mechanics:statistics:InsufficientTangentModulusSupport", ...
        ["The selected strain interval must be supported by at least %d " ...
         "specimens at every grid point."], minimumSpecimens);
end

meanModulus = mean(modulusMatrix, 2, "omitnan");
medianModulus = median(modulusMatrix, 2, "omitnan");
centralStatistic = lower(string(config.centralStatistic));
switch centralStatistic
    case "mean"
        centralModulus = meanModulus;
    case "median"
        centralModulus = medianModulus;
    otherwise
        error("mechanics:statistics:UnknownCentralStatistic", ...
            "centralStatistic must be 'mean' or 'median'.");
end

standardDeviation = std(modulusMatrix, 0, 2, "omitnan");
standardError = standardDeviation ./ sqrt(specimenCountByPoint);
confidenceLower = nan(gridPointCount, 1);
confidenceUpper = nan(gridPointCount, 1);

if config.bootstrap.enabled
    for pointIndex = 1:gridPointCount
        values = modulusMatrix(pointIndex, :);
        values = values(isfinite(values));
        pointConfig = config.bootstrap;
        pointConfig.randomSeed = config.bootstrap.randomSeed + pointIndex - 1;
        if centralStatistic == "mean"
            interval = mechanics.statistics.bootstrapMeanConfidenceInterval( ...
                values, pointConfig);
        else
            interval = localBootstrapMedian(values, pointConfig);
        end
        confidenceLower(pointIndex) = interval.lower;
        confidenceUpper(pointIndex) = interval.upper;
    end
end

aggregate.specimenIds = specimenIds;
aggregate.specimenCount = curveCount;
aggregate.specimenCountByPoint = specimenCountByPoint;
aggregate.minimumSpecimens = minimumSpecimens;
aggregate.strainRange = strainLimits;
aggregate.strain = strainGrid;
aggregate.modulusMatrix = modulusMatrix;
aggregate.meanModulus = meanModulus;
aggregate.medianModulus = medianModulus;
aggregate.centralStatistic = centralStatistic;
aggregate.centralModulus = centralModulus;
aggregate.standardDeviation = standardDeviation;
aggregate.standardError = standardError;
aggregate.confidenceLower = confidenceLower;
aggregate.confidenceUpper = confidenceUpper;
aggregate.config = config;
end

function strainLimits = localSupportedStrainRange( ...
        minimumStrain, maximumStrain, minimumSpecimens, config)
rangeMode = lower(string(config.strainRangeMode));
switch rangeMode
    case "explicit"
        strainLimits = config.explicitStrainRange;
    case "common-overlap"
        endpoints = unique(sort([minimumStrain; maximumStrain]));
        if numel(endpoints) < 2
            error("mechanics:statistics:InvalidTangentModulusRange", ...
                "Tangent-modulus curves must span a nonzero strain range.");
        end

        intervalSupported = false(numel(endpoints) - 1, 1);
        for index = 1:numel(intervalSupported)
            midpoint = mean(endpoints(index:index + 1));
            intervalSupported(index) = sum( ...
                minimumStrain <= midpoint & maximumStrain >= midpoint) ...
                >= minimumSpecimens;
        end

        runs = localLogicalRuns(intervalSupported);
        if isempty(runs)
            error("mechanics:statistics:InsufficientTangentModulusSupport", ...
                ["No strain interval is supported by at least %d " ...
                 "specimens."], minimumSpecimens);
        end

        runLengths = endpoints(runs(:, 2) + 1) - endpoints(runs(:, 1));
        [~, selectedIndex] = max(runLengths);
        selectedRun = runs(selectedIndex, :);
        strainLimits = [ ...
            endpoints(selectedRun(1)), ...
            endpoints(selectedRun(2) + 1)];
    otherwise
        error("mechanics:statistics:UnknownStrainRangeMode", ...
            "Unknown strain range mode: %s", config.strainRangeMode);
end

if numel(strainLimits) ~= 2 || any(~isfinite(strainLimits)) || ...
        strainLimits(2) <= strainLimits(1)
    error("mechanics:statistics:InvalidTangentModulusRange", ...
        "The tangent-modulus strain range must contain increasing finite values.");
end

supportAtStart = sum( ...
    minimumStrain <= strainLimits(1) & maximumStrain >= strainLimits(1));
supportAtEnd = sum( ...
    minimumStrain <= strainLimits(2) & maximumStrain >= strainLimits(2));
if supportAtStart < minimumSpecimens || supportAtEnd < minimumSpecimens
    error("mechanics:statistics:TangentModulusRangeOutsideSupport", ...
        ["The requested strain range must be supported by at least %d " ...
         "specimens."], minimumSpecimens);
end
end

function runs = localLogicalRuns(mask)
mask = logical(mask(:));
changes = diff([false; mask; false]);
starts = find(changes == 1);
stops = find(changes == -1) - 1;
runs = [starts, stops];
end

function interval = localBootstrapMedian(values, config)
values = values(isfinite(values));
rng(config.randomSeed, "twister");
iterations = round(config.iterations);
samples = nan(iterations, 1);
for index = 1:iterations
    draw = values(randi(numel(values), numel(values), 1));
    samples(index) = median(draw);
end
alpha = 1 - config.confidenceLevel;
probabilities = [alpha / 2, 1 - alpha / 2];
ordered = sort(samples);
indices = 1 + (iterations - 1) .* probabilities;
interval.lower = interp1(1:iterations, ordered, indices(1), "linear");
interval.upper = interp1(1:iterations, ordered, indices(2), "linear");
interval.median = median(samples);
end

function [strain, modulus] = localPrepareCurve(strain, modulus)
strain = strain(:);
modulus = modulus(:);
if numel(strain) ~= numel(modulus)
    error("mechanics:statistics:TangentModulusCurveSizeMismatch", ...
        "Tangent-modulus strain and values must have equal lengths.");
end
valid = isfinite(strain) & isfinite(modulus);
strain = strain(valid);
modulus = modulus(valid);
if numel(strain) < 2
    error("mechanics:statistics:InsufficientTangentModulusData", ...
        "Every tangent-modulus curve must contain at least two finite values.");
end
[strain, order] = sort(strain, "ascend");
modulus = modulus(order);
[uniqueStrain, ~, groupIndex] = unique(strain, "stable");
if numel(uniqueStrain) < numel(strain)
    modulus = accumarray(groupIndex, modulus, [], @mean);
    strain = uniqueStrain;
end
if numel(strain) < 2 || strain(end) <= strain(1)
    error("mechanics:statistics:InvalidTangentModulusCurveRange", ...
        "Every tangent-modulus curve must span a nonzero strain range.");
end
end
