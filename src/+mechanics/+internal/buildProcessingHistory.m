function history = buildProcessingHistory(config)
%BUILDPROCESSINGHISTORY Build a readable processing audit trail.
history = strings(0,1);
if config.removeNonfinite
    history(end+1) = "Removed nonfinite samples";
end
history(end+1) = sprintf( ...
    "Selected samples %g to %g", config.startIndex, config.endIndex);

if isfield(config, "zeroReference")
    zero = config.zeroReference;
    method = lower(string(zero.method));
    switch method
        case "first-sample"
            history(end+1) = "Referenced force and displacement to the first selected sample";
        case "preload-threshold"
            history(end+1) = sprintf( ...
                "Referenced force and displacement at preload threshold %.6g", ...
                zero.preloadForce);
        case "manual-index"
            history(end+1) = sprintf( ...
                "Referenced force and displacement at manual index %d", ...
                round(zero.manualIndex));
        case "none"
            history(end+1) = "Preserved the original force and displacement reference";
        otherwise
            history(end+1) = "Applied configured zero-reference method: " + method;
    end
elseif isfield(config, "zeroForce") || isfield(config, "zeroDisplacement")
    if isfield(config, "zeroForce") && config.zeroForce
        history(end+1) = "Zeroed force at selected start";
    end
    if isfield(config, "zeroDisplacement") && config.zeroDisplacement
        history(end+1) = "Zeroed displacement at selected start";
    end
end

if config.smoothing.enabled
    history(end+1) = sprintf( ...
        "Applied %s smoothing, frame %d", ...
        config.smoothing.method, config.smoothing.frameLength);
end
end