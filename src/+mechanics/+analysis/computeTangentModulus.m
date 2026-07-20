function result = computeTangentModulus(curve, config)
%COMPUTETANGENTMODULUS Compute tangent modulus and a window median.
if ~isfield(curve, "strain") || ~isfield(curve, "stress")
    error("mechanics:analysis:MissingMeasures", "Compute stress and strain before tangent modulus.");
end
strain = curve.strain(:);
stress = curve.stress(:);
tangentModulus = gradient(stress) ./ gradient(strain);
startIndex = max(1, round(config.modulusStartIndex));
endIndex = min(numel(tangentModulus), startIndex + round(config.modulusWindowLength) - 1);
window = tangentModulus(startIndex:endIndex);
result.tangentModulus = tangentModulus;
result.medianModulus = median(window, "omitnan");
result.windowIndices = [startIndex, endIndex];
result.config = config;
if config.smoothModulusForPlot
    smoothing.method = "sgolay";
    smoothing.frameLength = config.modulusPlotFrameLength;
    smoothing.polynomialOrder = 3;
    result.tangentModulusForPlot = mechanics.internal.smoothVector(tangentModulus, smoothing);
else
    result.tangentModulusForPlot = tangentModulus;
end
end
