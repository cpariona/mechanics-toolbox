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

if config.includeIndividualCurves
    figureHandle = figure("Visible", "off", "Color", "w");
    axesHandle = axes(figureHandle);
    hold(axesHandle, "on");

    records = study.analysis.records;
    for index = 1:numel(records)
        if records(index).status ~= "processed"
            continue;
        end

        specimen = records(index).specimen;
        plot(axesHandle, specimen.processed.strain, ...
            specimen.processed.stress, "LineWidth", 1.1, ...
            "DisplayName", char(records(index).specimenId));
    end

    xlabel(axesHandle, "Strain");
    ylabel(axesHandle, "Stress");
    title(axesHandle, "Processed specimen curves");
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

    plot(axesHandle, curves.strain, curves.meanStress, ...
        "LineWidth", 1.6, "DisplayName", "Mean stress");
    xlabel(axesHandle, "Strain");
    ylabel(axesHandle, "Stress");
    title(axesHandle, "Population stress-strain response");
    grid(axesHandle, "on");
    box(axesHandle, "on");
    legend(axesHandle, "Location", "best");

    filename = fullfile(folder, "population_curve." + format);
    exportgraphics(figureHandle, filename, ...
        "Resolution", config.figureResolution);
    outputFiles.populationCurve = string(filename);
    localClose(figureHandle, config);
end

if config.includeFractureMetrics && ...
        isfield(study.analysis, "fractureSummary") && ...
        ~isempty(study.analysis.fractureSummary)
    summary = study.analysis.fractureSummary;
    figureHandle = figure("Visible", "off", "Color", "w");
    tiledlayout(figureHandle, 1, 2, ...
        "TileSpacing", "compact", "Padding", "compact");

    labels = categorical(summary.SpecimenId);
    labels = reordercats(labels, cellstr(summary.SpecimenId));

    nexttile;
    bar(labels, summary.PeakForce);
    ylabel("Peak force");
    grid on;
    box on;

    nexttile;
    bar(labels, summary.EnergyToPeak);
    ylabel("Energy to peak");
    grid on;
    box on;

    filename = fullfile(folder, "fracture_metrics." + format);
    exportgraphics(figureHandle, filename, ...
        "Resolution", config.figureResolution);
    outputFiles.fractureMetrics = string(filename);
    localClose(figureHandle, config);
end
end

function localClose(figureHandle, config)
if config.closeFiguresAfterExport && isgraphics(figureHandle)
    close(figureHandle);
end
end
