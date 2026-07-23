function result = selectCompressionCycle(rawCurve, config)
%SELECTCOMPRESSIONCYCLE Select a complete compression cycle and analysis branch.
arguments
    rawCurve (1,1) struct
    config (1,1) struct
end

if ~isfield(rawCurve, "force") || ~isfield(rawCurve, "displacement")
    error("mechanics:segmentation:InvalidCompressionCurve", ...
        "rawCurve must contain force and displacement.");
end
force = rawCurve.force(:);
displacement = rawCurve.displacement(:);
if numel(force) ~= numel(displacement)
    error("mechanics:segmentation:CompressionSizeMismatch", ...
        "Force and displacement must have equal lengths.");
end
if numel(force) < config.minimumObservations
    error("mechanics:segmentation:InsufficientCompressionData", ...
        "Compression data contain fewer than %d observations.", ...
        config.minimumObservations);
end

if ~config.enabled
    selectedIndices = (1:numel(force))';
    result.cycleCount = 0;
    result.selectedCycleIndex = NaN;
    result.cycleStartIndex = 1;
    result.loadingEndIndex = numel(force);
    result.cycleEndIndex = numel(force);
else
    frameLength = max(1, round(config.smoothingFrameLength));
    if mod(frameLength,2) == 0
        frameLength = frameLength + 1;
    end
    smoothDisplacement = movmean(displacement, frameLength, "Endpoints", "shrink");
    direction = lower(string(config.loadingDirection));
    if direction == "decreasing"
        smoothDisplacement = -smoothDisplacement;
    elseif direction ~= "increasing"
        error("mechanics:segmentation:UnknownCompressionDirection", ...
            "loadingDirection must be 'increasing' or 'decreasing'.");
    end

    derivative = diff(smoothDisplacement);
    derivativeSign = sign(derivative);
    derivativeSign = localFillZeroSigns(derivativeSign);
    maxima = find(derivativeSign(1:end-1) > 0 & ...
        derivativeSign(2:end) < 0) + 1;
    minima = find(derivativeSign(1:end-1) < 0 & ...
        derivativeSign(2:end) > 0) + 1;
    minima = unique([1; minima(:); numel(displacement)]);

    cycles = zeros(0,3);
    for peakIndex = maxima(:)'
        startCandidates = minima(minima < peakIndex);
        endCandidates = minima(minima > peakIndex);
        if isempty(startCandidates) || isempty(endCandidates)
            continue;
        end
        startIndex = startCandidates(end);
        endIndex = endCandidates(1);
        amplitude = smoothDisplacement(peakIndex) - smoothDisplacement(startIndex);
        if amplitude < config.minimumCycleAmplitude
            continue;
        end
        cycles(end+1,:) = [startIndex, peakIndex, endIndex]; %#ok<AGROW>
    end

    if isempty(cycles)
        error("mechanics:segmentation:NoCompleteCompressionCycle", ...
            "No complete compression cycle was detected.");
    end

    switch lower(string(config.selection))
        case "last-complete-cycle"
            selectedCycleIndex = size(cycles,1);
        case "first-complete-cycle"
            selectedCycleIndex = 1;
        otherwise
            error("mechanics:segmentation:UnknownCycleSelection", ...
                "Unknown compression-cycle selection: %s", config.selection);
    end

    selectedCycle = cycles(selectedCycleIndex,:);
    cycleStartIndex = selectedCycle(1);
    loadingEndIndex = selectedCycle(2);
    cycleEndIndex = selectedCycle(3);

    switch lower(string(config.branch))
        case "loading"
            selectedIndices = (cycleStartIndex:loadingEndIndex)';
        case "unloading"
            selectedIndices = (loadingEndIndex:cycleEndIndex)';
        case "full-cycle"
            selectedIndices = (cycleStartIndex:cycleEndIndex)';
        otherwise
            error("mechanics:segmentation:UnknownCompressionBranch", ...
                "Unknown compression branch: %s", config.branch);
    end

    result.cycleCount = size(cycles,1);
    result.selectedCycleIndex = selectedCycleIndex;
    result.cycleStartIndex = cycleStartIndex;
    result.loadingEndIndex = loadingEndIndex;
    result.cycleEndIndex = cycleEndIndex;
    result.detectedCycles = cycles;
end

selectedRaw.force = force(selectedIndices);
selectedRaw.displacement = displacement(selectedIndices);
if isfield(rawCurve, "time")
    selectedRaw.time = rawCurve.time(selectedIndices);
end
if isfield(rawCurve, "units")
    selectedRaw.units = rawCurve.units;
end

result.selectedIndices = selectedIndices;
result.selectedRaw = selectedRaw;
result.branch = string(config.branch);
result.loadingDirection = string(config.loadingDirection);
result.config = config;
end

function values = localFillZeroSigns(values)
if isempty(values)
    return;
end
for index = 2:numel(values)
    if values(index) == 0
        values(index) = values(index-1);
    end
end
for index = numel(values)-1:-1:1
    if values(index) == 0
        values(index) = values(index+1);
    end
end
end