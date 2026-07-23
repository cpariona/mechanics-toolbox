function files = exportCompressionStudyFigures(study, config)
%EXPORTCOMPRESSIONSTUDYFIGURES Export compression-cycle and branch figures.
arguments
    study (1,1) struct
    config (1,1) struct = mechanics.config.compressionStudyReportConfig()
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end
format = lower(string(config.figureFormat));
files = struct();
titleText = localStudyTitle(study, config);
specimen = study.specimen;
units = specimen.processed.units;

if config.includeCycleOverview
    fig = figure("Visible", "off", "Color", "w");
    ax = axes(fig);
    hold(ax, "on");
    cycleRaw = specimen.fullCycleRaw;
    peakIndex = study.cycle.loadingEndIndex - study.cycle.cycleStartIndex + 1;
    plot(ax, cycleRaw.displacement, cycleRaw.force, ...
        "LineWidth", 1.2, "DisplayName", "Selected full cycle");
    plot(ax, cycleRaw.displacement(1:peakIndex), ...
        cycleRaw.force(1:peakIndex), "LineWidth", 1.8, ...
        "DisplayName", "Loading branch");
    plot(ax, cycleRaw.displacement(peakIndex:end), ...
        cycleRaw.force(peakIndex:end), "LineWidth", 1.8, ...
        "DisplayName", "Unloading branch");
    xlabel(ax, localUnitLabel("Compression displacement", units.displacement));
    ylabel(ax, localUnitLabel("Compression force", units.force));
    title(ax, titleText + " - selected compression cycle", "Interpreter", "none");
    grid(ax, "on");
    box(ax, "on");
    legend(ax, "Location", "best", "Interpreter", "none");
    filename = fullfile(folder, "compression_cycle." + format);
    exportgraphics(fig, filename, "Resolution", config.figureResolution);
    files.cycleOverview = string(filename);
    localClose(fig, config);
end

if config.includeSelectedBranch
    fig = figure("Visible", "off", "Color", "w");
    ax = axes(fig);
    plot(ax, specimen.processed.strain, specimen.processed.stress, ...
        "LineWidth", 1.5);
    xlabel(ax, localUnitLabel("Compression strain", units.strain));
    ylabel(ax, localUnitLabel("Compression stress", units.stress));
    title(ax, titleText + " - selected loading response", "Interpreter", "none");
    grid(ax, "on");
    box(ax, "on");
    filename = fullfile(folder, "compression_response." + format);
    exportgraphics(fig, filename, "Resolution", config.figureResolution);
    files.selectedBranch = string(filename);
    localClose(fig, config);
end

if config.includeTangentModulus
    modulus = specimen.analysis.tangentModulus;
    fig = figure("Visible", "off", "Color", "w");
    ax = axes(fig);
    plot(ax, modulus.strain, modulus.tangentModulusForPlot, ...
        "LineWidth", 1.4);
    hold(ax, "on");
    xline(ax, modulus.summaryStrainRange(1), "--", "Summary range");
    xline(ax, modulus.summaryStrainRange(2), "--", ...
        "HandleVisibility", "off");
    xlabel(ax, localUnitLabel("Compression strain", units.strain));
    ylabel(ax, localUnitLabel("Tangent modulus", units.stress));
    title(ax, titleText + " - tangent modulus", "Interpreter", "none");
    grid(ax, "on");
    box(ax, "on");
    filename = fullfile(folder, "compression_tangent_modulus." + format);
    exportgraphics(fig, filename, "Resolution", config.figureResolution);
    files.tangentModulus = string(filename);
    localClose(fig, config);
end
end

function titleText = localStudyTitle(study, config)
if string(config.studyTitle) ~= "auto"
    titleText = string(config.studyTitle);
else
    [~, filename] = fileparts(string(study.sourceFile));
    titleText = replace(filename, ["_", "-"], " ");
    if strlength(titleText) == 0
        titleText = "Compression study";
    end
end
end

function label = localUnitLabel(name, unit)
unit = string(unit);
if strlength(unit) == 0
    label = string(name);
else
    label = string(name) + " [" + unit + "]";
end
end

function localClose(fig, config)
if config.closeFiguresAfterExport && isgraphics(fig)
    close(fig);
end
end