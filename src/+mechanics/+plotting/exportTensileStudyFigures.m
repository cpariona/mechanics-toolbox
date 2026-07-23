function outputFiles = exportTensileStudyFigures(study, config)
%EXPORTTENSILESTUDYFIGURES Export standard figures for a tensile study.
arguments
    study (1,1) struct
    config (1,1) struct = mechanics.config.studyReportConfig()
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

outputFiles = struct();
format = lower(string(config.figureFormat));
records = study.analysis.records;
units = localStudyUnits(records);
studyTitle = localStudyTitle(study, config);
strainLabel = localUnitLabel("Engineering strain, \epsilon", units.strain);
stressLabel = localUnitLabel("Engineering stress, \sigma", units.stress);
modulusLabel = localUnitLabel("Tangent modulus", units.stress);

if config.includeIndividualCurves
    figureHandle = figure("Visible", "off", "Color", "w");
    axesHandle = axes(figureHandle);
    hold(axesHandle, "on");

    for index = 1:numel(records)
        if records(index).status ~= "processed"
            continue;
        end
        specimen = records(index).specimen;
        plot(axesHandle, specimen.processed.strain, ...
            specimen.processed.stress, "LineWidth", 1.1, ...
            "DisplayName", char(records(index).specimenId));
    end

    xlabel(axesHandle, strainLabel);
    ylabel(axesHandle, stressLabel);
    title(axesHandle, studyTitle + " — processed specimen curves", ...
        "Interpreter", "none");
    grid(axesHandle, "on");
    box(axesHandle, "on");
    legend(axesHandle, "Location", "best", "Interpreter", "none");

    filename = fullfile(folder, "individual_curves." + format);
    exportgraphics(figureHandle, filename, ...
        "Resolution", config.figureResolution);
    outputFiles.individualCurves = string(filename);
    localClose(figureHandle, config);
end

if config.includePopulationCurve && ...
        isfield(study, "population") && ...
        isfield(study.population, "curves")
    curves = study.population.curves;
    figureHandle = figure("Visible", "off", "Color", "w");
    axesHandle = axes(figureHandle);
    hold(axesHandle, "on");

    if all(isfinite(curves.confidenceLower)) && ...
            all(isfinite(curves.confidenceUpper))
        fill(axesHandle, ...
            [curves.strain; flipud(curves.strain)], ...
            [curves.confidenceLower; flipud(curves.confidenceUpper)], ...
            [0.85 0.85 0.85], "EdgeColor", "none", ...
            "DisplayName", "Bootstrap confidence interval");
    end

    plot(axesHandle, curves.strain, curves.centralStress, ...
        "LineWidth", 1.6, "DisplayName", ...
        char(curves.centralStatistic + " stress"));
    xlabel(axesHandle, strainLabel);
    ylabel(axesHandle, stressLabel);
    title(axesHandle, studyTitle + " — population response", ...
        "Interpreter", "none");
    grid(axesHandle, "on");
    box(axesHandle, "on");
    legend(axesHandle, "Location", "best");

    filename = fullfile(folder, "population_curve." + format);
    exportgraphics(figureHandle, filename, ...
        "Resolution", config.figureResolution);
    outputFiles.populationCurve = string(filename);
    localClose(figureHandle, config);
end

includePeakMetrics = localGetLogical(config, "includePeakMetrics", ...
    localGetLogical(config, "includeFractureMetrics", true));
if includePeakMetrics && ...
        isfield(study.analysis, "fractureSummary") && ...
        ~isempty(study.analysis.fractureSummary)
    summary = study.analysis.fractureSummary;
    figureHandle = figure("Visible", "off", "Color", "w");
    tiledlayout(figureHandle, 1, 3, ...
        "TileSpacing", "compact", "Padding", "compact");

    labels = categorical(summary.SpecimenId);
    labels = reordercats(labels, cellstr(summary.SpecimenId));

    nexttile;
    bar(labels, summary.PeakForce);
    ylabel(localUnitLabel("Peak force", units.force));
    title("Peak force");
    grid on;
    box on;

    nexttile;
    bar(labels, summary.PeakStress);
    ylabel(localUnitLabel("Peak stress", units.stress));
    title("Peak stress");
    grid on;
    box on;

    nexttile;
    bar(labels, summary.EnergyToPeak);
    ylabel(localUnitLabel("Energy to peak", units.energy));
    title("Energy to peak");
    grid on;
    box on;

    sgtitle(figureHandle, studyTitle + " — peak metrics", ...
        "Interpreter", "none");
    filename = fullfile(folder, "peak_metrics." + format);
    exportgraphics(figureHandle, filename, ...
        "Resolution", config.figureResolution);
    outputFiles.peakMetrics = string(filename);
    localClose(figureHandle, config);
end

if config.includeTangentModulus
    figureHandle = figure("Visible", "off", "Color", "w");
    axesHandle = axes(figureHandle);
    hold(axesHandle, "on");
    plotted = false;
    for index = 1:numel(records)
        if records(index).status ~= "processed"
            continue;
        end
        modulus = records(index).specimen.analysis.tangentModulus;
        plot(axesHandle, modulus.strain, modulus.tangentModulusForPlot, ...
            "LineWidth", 1.1, ...
            "DisplayName", char(records(index).specimenId));
        plotted = true;
    end
    if plotted
        summaryRange = records(find([records.status] == "processed", 1, "first")) ...
            .specimen.analysis.tangentModulus.summaryStrainRange;
        xline(axesHandle, summaryRange(1), "--", "Summary range");
        xline(axesHandle, summaryRange(2), "--", "HandleVisibility", "off");
        xlabel(axesHandle, strainLabel);
        ylabel(axesHandle, modulusLabel);
        title(axesHandle, studyTitle + " — tangent modulus", ...
            "Interpreter", "none");
        grid(axesHandle, "on");
        box(axesHandle, "on");
        legend(axesHandle, "Location", "best", "Interpreter", "none");
        filename = fullfile(folder, "tangent_modulus." + format);
        exportgraphics(figureHandle, filename, ...
            "Resolution", config.figureResolution);
        outputFiles.tangentModulus = string(filename);
    end
    localClose(figureHandle, config);
end
end

function units = localStudyUnits(records)
units.force = "N";
units.displacement = "mm";
units.strain = "-";
units.stress = "MPa";
units.energy = "mJ";
index = find([records.status] == "processed", 1, "first");
if isempty(index)
    return;
end
specimen = records(index).specimen;
if isfield(specimen.processed, "units")
    source = specimen.processed.units;
    names = fieldnames(source);
    for k = 1:numel(names)
        units.(names{k}) = string(source.(names{k}));
    end
end
if units.strain == "1"
    units.strain = "-";
end
end

function titleText = localStudyTitle(study, config)
if string(config.studyTitle) ~= "auto"
    titleText = string(config.studyTitle);
    return;
end
[~, filename] = fileparts(string(study.sourceFile));
titleText = replace(filename, ["_", "-"], " ");
if strlength(titleText) == 0
    titleText = "Mechanical test";
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

function value = localGetLogical(config, fieldName, defaultValue)
if isfield(config, fieldName)
    value = logical(config.(fieldName));
else
    value = logical(defaultValue);
end
end

function localClose(figureHandle, config)
if config.closeFiguresAfterExport && isgraphics(figureHandle)
    close(figureHandle);
end
end