function files = exportCompressionPopulationFigures(populationStudy, exportConfig)
%EXPORTCOMPRESSIONPOPULATIONFIGURES Export group curves and metric summaries.
arguments
    populationStudy (1,1) struct
    exportConfig (1,1) struct
end
folder = string(exportConfig.outputFolder);
if ~isfolder(folder), mkdir(folder); end
resolution = exportConfig.figureResolution;
files = struct();

fig = figure("Visible","off");
hold on;
for index = 1:numel(populationStudy.groups)
    group = populationStudy.groups(index);
    if group.status ~= "processed", continue; end
    plot(group.curves.strain, group.curves.centralStress, ...
        "DisplayName", group.name, "LineWidth", 1.5);
end
xlabel("Compression strain"); ylabel("Compression stress");
title("Compression population curves"); grid on; legend("Location","best");
curveFile = fullfile(folder, "compression_population_curves.png");
exportgraphics(fig, curveFile, "Resolution", resolution); close(fig);
files.curves = string(curveFile);

metrics = populationStudy.summary(populationStudy.summary.Status=="processed",:);
if ~isempty(metrics)
    fig = figure("Visible","off");
    groups = categorical(metrics.Group);
    scatter(groups, metrics.HysteresisFraction, "filled");
    ylabel("Hysteresis fraction"); title("Compression hysteresis by group"); grid on;
    hysteresisFile = fullfile(folder, "compression_hysteresis_by_group.png");
    exportgraphics(fig, hysteresisFile, "Resolution", resolution); close(fig);
    files.hysteresis = string(hysteresisFile);

    fig = figure("Visible","off");
    scatter(groups, metrics.MedianTangentModulus, "filled");
    ylabel("Median tangent modulus"); title("Compression tangent modulus by group"); grid on;
    modulusFile = fullfile(folder, "compression_modulus_by_group.png");
    exportgraphics(fig, modulusFile, "Resolution", resolution); close(fig);
    files.modulus = string(modulusFile);
end
end
