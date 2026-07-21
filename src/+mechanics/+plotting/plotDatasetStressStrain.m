function figureHandle = plotDatasetStressStrain(analysis)
%PLOTDATASETSTRESSSTRAIN Overlay processed stress-strain curves.
arguments
    analysis (1,1) struct
end

figureHandle = figure("Color", "w");
axesHandle = axes(figureHandle);
hold(axesHandle, "on");

processedCount = 0;

for index = 1:numel(analysis.records)
    record = analysis.records(index);

    if record.status ~= "processed"
        continue;
    end

    specimen = record.specimen;
    plot(axesHandle, ...
        specimen.processed.strain, ...
        specimen.processed.stress, ...
        "LineWidth", 1.2, ...
        "DisplayName", char(string(specimen.id)));
    processedCount = processedCount + 1;
end

xlabel(axesHandle, "Strain");
ylabel(axesHandle, "Stress");
grid(axesHandle, "on");
box(axesHandle, "on");

if processedCount > 0
    legend(axesHandle, "Location", "best", "Interpreter", "none");
else
    text(axesHandle, 0.5, 0.5, "No processed specimens", ...
        "Units", "normalized", ...
        "HorizontalAlignment", "center");
end
end
