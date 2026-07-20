function output = smoothVector(input, config)
%SMOOTHVECTOR Apply validated one-dimensional smoothing.
input = input(:);
frameLength = min(round(config.frameLength), numel(input));
if mod(frameLength, 2) == 0, frameLength = frameLength - 1; end
minimumFrame = config.polynomialOrder + 2;
if mod(minimumFrame, 2) == 0, minimumFrame = minimumFrame + 1; end
if frameLength < minimumFrame
    output = input;
    return
end
switch lower(string(config.method))
    case "sgolay"
        output = smoothdata(input, "sgolay", frameLength, "Degree", config.polynomialOrder);
    case "movmean"
        output = smoothdata(input, "movmean", frameLength);
    otherwise
        error("mechanics:preprocessing:UnknownSmoothing", "Unknown smoothing method: %s", config.method);
end
end
