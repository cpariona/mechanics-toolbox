function history = buildProcessingHistory(config)
%BUILDPROCESSINGHISTORY Build a readable processing audit trail.
history = strings(0,1);
if config.removeNonfinite, history(end+1) = "Removed nonfinite samples"; end
history(end+1) = sprintf("Selected samples %g to %g", config.startIndex, config.endIndex);
if config.zeroForce, history(end+1) = "Zeroed force at selected start"; end
if config.zeroDisplacement, history(end+1) = "Zeroed displacement at selected start"; end
if config.smoothing.enabled
    history(end+1) = sprintf("Applied %s smoothing, frame %d", config.smoothing.method, config.smoothing.frameLength);
end
end
