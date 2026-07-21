function figureHandle = plotFractureMetrics(fractureSummary)
%PLOTFRACTUREMETRICS Plot core fracture metrics by specimen.
arguments
    fractureSummary table
end

figureHandle = figure("Color", "w");
tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

labels = categorical(fractureSummary.SpecimenId);
labels = reordercats(labels, cellstr(fractureSummary.SpecimenId));

nexttile;
bar(labels, fractureSummary.PeakForce);
ylabel("Peak force");
grid on;
box on;

nexttile;
bar(labels, fractureSummary.PeakDisplacement);
ylabel("Peak displacement");
grid on;
box on;

nexttile;
bar(labels, fractureSummary.EnergyToPeak);
ylabel("Energy to peak");
grid on;
box on;

nexttile;
bar(labels, 100 .* fractureSummary.PostPeakDropFraction);
ylabel("Post-peak drop (%)");
grid on;
box on;
end
