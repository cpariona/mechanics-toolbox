function [medianCurve, lowerCI, upperCI] = bootstrapMedianCI(data, numberOfResamples, confidenceLevel)
%BOOTSTRAPMEDIANCI Median and percentile bootstrap confidence interval.
arguments
    data double
    numberOfResamples (1,1) double {mustBeInteger,mustBePositive} = 10000
    confidenceLevel (1,1) double {mustBeGreaterThan(confidenceLevel,0),mustBeLessThan(confidenceLevel,100)} = 95
end
if isvector(data), data = data(:)'; end
medianCurve = median(data, 2, "omitnan");
numberOfObservations = size(data, 2);
if numberOfObservations < 2
    lowerCI = medianCurve;
    upperCI = medianCurve;
    return
end
alpha = (100 - confidenceLevel) / 2;
bootstrapStatistics = bootstrp(numberOfResamples, @(index) median(data(:, index), 2, "omitnan")', 1:numberOfObservations);
lowerCI = prctile(bootstrapStatistics, alpha, 1)';
upperCI = prctile(bootstrapStatistics, 100 - alpha, 1)';
end
