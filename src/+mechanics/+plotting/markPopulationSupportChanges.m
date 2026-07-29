function markPopulationSupportChanges(axesHandle, x, specimenCount)
%MARKPOPULATIONSUPPORTCHANGES Mark changes in pointwise specimen support.
arguments
    axesHandle (1,1) matlab.graphics.axis.Axes
    x {mustBeNumeric, mustBeReal}
    specimenCount {mustBeNumeric, mustBeReal}
end

x = x(:);
specimenCount = specimenCount(:);
if numel(x) ~= numel(specimenCount) || isempty(x)
    return;
end
valid = isfinite(x) & isfinite(specimenCount);
x = x(valid);
specimenCount = specimenCount(valid);
if isempty(x)
    return;
end

changeIndices = find(diff(specimenCount) ~= 0) + 1;
for index = changeIndices(:)'
    xline(axesHandle, x(index), ":", ...
        "n=" + string(specimenCount(index)), ...
        "HandleVisibility", "off", ...
        "LabelOrientation", "aligned", ...
        "LabelVerticalAlignment", "bottom");
end
end