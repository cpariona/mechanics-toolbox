function aggregate = aggregateStressStrain(specimens, config)
%AGGREGATESTRESSSTRAIN Interpolate replicate curves onto a common strain grid.
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
minimumStrain = nan(curveCount, 1);
maximumStrain = nan(curveCount, 1);
preparedStrain = cell(curveCount, 1);
preparedStress = cell(curveCount, 1);
specimenIds = strings(curveCount, 1);

for index = 1:curveCount
    specimen = specimens(index);

    if ~isfield(specimen, "processed") || ...
            ~isfield(specimen.processed, "strain") || ...
            ~isfield(specimen.processed, "stress")
        error("mechanics:statistics:MissingProcessedCurve", ...
            "Every specimen must contain processed strain and stress.");
    end

    [strain, stress] = localPrepareCurve( ...
        specimen.processed.strain, specimen.processed.stress);

    preparedStrain{index} = strain;
    preparedStress{index} = stress;
    minimumStrain(index) = min(strain);
    maximumStrain(index) = max(strain);

    if isfield(specimen, "id")
        specimenIds(index) = string(specimen.id);
    else
        specimenIds(index) = "specimen-" + index;
    end
end

switch lower(string(config.strainRangeMode))
    case "common-overlap"
        strainLimits = [max(minimumStrain), min(maximumStrain)];

    case "explicit"
        strainLimits = config.explicitStrainRange;

    otherwise
        error("mechanics:statistics:UnknownStrainRangeMode", ...
            "Unknown strain range mode: %s", config.strainRangeMode);
end

if numel(strainLimits) ~= 2 || ...
        any(~isfinite(strainLimits)) || ...
        strainLimits(2) <= strainLimits(1)
    error("mechanics:statistics:InvalidStrainRange", ...
        "The aggregation strain range must contain two increasing finite values.");
end

if strainLimits(1) < max(minimumStrain) || ...
        strainLimits(2) > min(maximumStrain)
    error("mechanics:statistics:StrainRangeOutsideOverlap", ...
        "The requested strain range is not covered by every specimen.");
end

gridPointCount = round(config.strainGridPointCount);
if ~isscalar(gridPointCount) || gridPointCount < 2
    error("mechanics:statistics:InvalidGridPointCount", ...
        "strainGridPointCount must be at least 2.");
end

strainGrid = linspace( ...
    strainLimits(1), strainLimits(2), gridPointCount)';
stressMatrix = nan(gridPointCount, curveCount);

for index = 1:curveCount
    stressMatrix(:, index) = interp1( ...
        preparedStrain{index}, preparedStress{index}, ...
        strainGrid, "linear");
end

meanStress = mean(stressMatrix, 2);
standardDeviation = std(stressMatrix, 0, 2);
standardError = standardDeviation ./ sqrt(curveCount);

confidenceLower = nan(gridPointCount, 1);
confidenceUpper = nan(gridPointCount, 1);

if config.bootstrap.enabled
    for pointIndex = 1:gridPointCount
        pointConfig = config.bootstrap;
        pointConfig.randomSeed = ...
            config.bootstrap.randomSeed + pointIndex - 1;

        interval = mechanics.statistics.bootstrapMeanConfidenceInterval( ...
            stressMatrix(pointIndex, :), pointConfig);

        confidenceLower(pointIndex) = interval.lower;
        confidenceUpper(pointIndex) = interval.upper;
    end
end

aggregate.specimenIds = specimenIds;
aggregate.specimenCount = curveCount;
aggregate.strainRange = strainLimits;
aggregate.strain = strainGrid;
aggregate.stressMatrix = stressMatrix;
aggregate.meanStress = meanStress;
aggregate.standardDeviation = standardDeviation;
aggregate.standardError = standardError;
aggregate.confidenceLower = confidenceLower;
aggregate.confidenceUpper = confidenceUpper;
aggregate.config = config;
end

function [strain, stress] = localPrepareCurve(strain, stress)
strain = strain(:);
stress = stress(:);

if numel(strain) ~= numel(stress)
    error("mechanics:statistics:CurveSizeMismatch", ...
        "Strain and stress must have equal lengths.");
end

valid = isfinite(strain) & isfinite(stress);
strain = strain(valid);
stress = stress(valid);

if numel(strain) < 2
    error("mechanics:statistics:InsufficientCurveData", ...
        "Every curve must contain at least two finite observations.");
end

[strain, order] = sort(strain, "ascend");
stress = stress(order);

[uniqueStrain, ~, groupIndex] = unique(strain, "stable");
if numel(uniqueStrain) < numel(strain)
    stress = accumarray(groupIndex, stress, [], @mean);
    strain = uniqueStrain;
end

if numel(strain) < 2 || strain(end) <= strain(1)
    error("mechanics:statistics:InvalidCurveRange", ...
        "Every curve must span a nonzero strain range.");
end
end
