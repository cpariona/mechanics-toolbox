function figureHandle = plotPeakMetrics(peakSummary)
%PLOTPEAKMETRICS Plot core peak metrics by specimen.
arguments
    peakSummary table
end

figureHandle = figure("Color", "w");
tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");
labels = categorical(peakSummary.SpecimenId);
labels = reordercats(labels, cellstr(peakSummary.SpecimenId));
nexttile;
bar(labels, peakSummary.PeakForce);
ylabel("Peak force"); grid on; box on;
nexttile;
bar(labels, peakSummary.PeakDisplacement);
ylabel("Peak displacement"); grid on; box on;
nexttile;
bar(labels, peakSummary.EnergyToPeak);
ylabel("Energy to peak"); grid on; box on;
nexttile;
bar(labels, 100 .* peakSummary.PostPeakDropFraction);
ylabel("Post-peak drop (%)"); grid on; box on;
end
