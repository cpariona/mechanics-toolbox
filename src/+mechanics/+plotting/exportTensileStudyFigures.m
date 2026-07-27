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
units = mechanics.plotting.resolveStudyUnits(records);
studyTitle = localStudyTitle(study, config);
strainLabel = mechanics.plotting.formatUnitLabel( ...
    "Engineering strain, \epsilon", units.strain);
stressLabel = mechanics.plotting.formatUnitLabel( ...
    localStressName(study), units.stress);
modulusLabel = mechanics.plotting.formatUnitLabel( ...
    "Tangent modulus", units.stress);

if config.includeIndividualCurves
    figureHandle = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1050 760]);
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
    legend(axesHandle, "Location", "southeast", "Interpreter", "none");
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
    if ~isfield(curves, "centralStress")
        curves.centralStress = curves.meanStress;
    end
    if ~isfield(curves, "centralStatistic")
        curves.centralStatistic = "mean";
    end
    figureHandle = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1050 760]);
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
        "LineWidth", 1.8, "DisplayName", ...
        char(curves.centralStatistic + " stress"));
    xlabel(axesHandle, strainLabel);
    ylabel(axesHandle, stressLabel);
    title(axesHandle, studyTitle + " — population response", ...
        "Interpreter", "none");
    grid(axesHandle, "on");
    box(axesHandle, "on");
    legend(axesHandle, "Location", "northwest");
    filename = fullfile(folder, "population_curve." + format);
    exportgraphics(figureHandle, filename, ...
        "Resolution", config.figureResolution);
    outputFiles.populationCurve = string(filename);
    localClose(figureHandle, config);
end

if config.includePeakMetrics && ...
        isfield(study.analysis, "peakSummary") && ...
        ~isempty(study.analysis.peakSummary)
    summary = study.analysis.peakSummary;
    figureHandle = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1300 720]);
    tiledlayout(figureHandle, 1, 3, ...
        "TileSpacing", "compact", "Padding", "loose");
    labels = categorical(summary.SpecimenId);
    labels = reordercats(labels, cellstr(summary.SpecimenId));

    axesHandle = nexttile;
    bar(axesHandle, labels, summary.PeakForce);
    ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
        "Peak force", units.force));
    title(axesHandle, "Peak force");
    axesHandle.XTickLabelRotation = 25;
    grid(axesHandle, "on");
    box(axesHandle, "on");

    axesHandle = nexttile;
    bar(axesHandle, labels, summary.PeakStress);
    ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
        "Peak nominal stress", units.stress));
    title(axesHandle, "Peak stress");
    axesHandle.XTickLabelRotation = 25;
    grid(axesHandle, "on");
    box(axesHandle, "on");

    axesHandle = nexttile;
    bar(axesHandle, labels, summary.EnergyToPeak);
    ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
        "Energy to peak", units.energy));
    title(axesHandle, "Energy to peak");
    axesHandle.XTickLabelRotation = 25;
    grid(axesHandle, "on");
    box(axesHandle, "on");

    sgtitle(figureHandle, studyTitle + " — peak metrics", ...
        "Interpreter", "none");
    filename = fullfile(folder, "peak_metrics." + format);
    exportgraphics(figureHandle, filename, ...
        "Resolution", config.figureResolution);
    outputFiles.peakMetrics = string(filename);
    localClose(figureHandle, config);
end

if config.includeTangentModulus
    figureHandle = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1050 760]);
    axesHandle = axes(figureHandle);
    hold(axesHandle, "on");
    plotted = false;
    firstProcessedIndex = find([records.status] == "processed", 1, "first");
    for index = 1:numel(records)
        if records(index).status ~= "processed" || ...
                ~isfield(records(index).specimen, "analysis") || ...
                ~isfield(records(index).specimen.analysis, "tangentModulus")
            continue;
        end
        modulus = records(index).specimen.analysis.tangentModulus;
        plot(axesHandle, modulus.strain, modulus.tangentModulusForPlot, ...
            "LineWidth", 1.0, ...
            "DisplayName", char(records(index).specimenId));
        plotted = true;
    end
    if plotted
        summaryRange = records(firstProcessedIndex).specimen.analysis ...
            .tangentModulus.summaryStrainRange;
        xline(axesHandle, summaryRange(1), "--", "Summary range", ...
            "HandleVisibility", "off", ...
            "LabelOrientation", "aligned", ...
            "LabelVerticalAlignment", "middle");
        xline(axesHandle, summaryRange(2), "--", ...
            "HandleVisibility", "off");
        xlabel(axesHandle, strainLabel);
        ylabel(axesHandle, modulusLabel);
        title(axesHandle, studyTitle + " — tangent modulus", ...
            "Interpreter", "none");
        grid(axesHandle, "on");
        box(axesHandle, "on");
        legend(axesHandle, "Location", "southwest", "Interpreter", "none");
        filename = fullfile(folder, "tangent_modulus." + format);
        exportgraphics(figureHandle, filename, ...
            "Resolution", config.figureResolution);
        outputFiles.tangentModulus = string(filename);
    end
    localClose(figureHandle, config);
end

if config.includeTangentModulus && ...
        isfield(study, "population") && ...
        isfield(study.population, "tangentModulus") && ...
        isfield(study.population, "tangentModulusStatus") && ...
        string(study.population.tangentModulusStatus) == "completed"
    tangent = study.population.tangentModulus;
    figureHandle = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1050 760]);
    axesHandle = axes(figureHandle);
    hold(axesHandle, "on");

    for index = 1:size(tangent.modulusMatrix, 2)
        plot(axesHandle, tangent.strain, tangent.modulusMatrix(:, index), ...
            "LineWidth", 0.65, "HandleVisibility", "off");
    end

    if all(isfinite(tangent.confidenceLower)) && ...
            all(isfinite(tangent.confidenceUpper))
        fill(axesHandle, ...
            [tangent.strain; flipud(tangent.strain)], ...
            [tangent.confidenceLower; flipud(tangent.confidenceUpper)], ...
            [0.85 0.85 0.85], "EdgeColor", "none", ...
            "DisplayName", "Bootstrap confidence interval");
    end

    plot(axesHandle, tangent.strain, tangent.centralModulus, ...
        "LineWidth", 2.2, "DisplayName", ...
        char(tangent.centralStatistic + " tangent modulus"));
    xlabel(axesHandle, strainLabel);
    ylabel(axesHandle, modulusLabel);
    title(axesHandle, studyTitle + " — population tangent modulus", ...
        "Interpreter", "none");
    grid(axesHandle, "on");
    box(axesHandle, "on");
    legend(axesHandle, "Location", "northwest");
    filename = fullfile(folder, "population_tangent_modulus." + format);
    exportgraphics(figureHandle, filename, ...
        "Resolution", config.figureResolution);
    outputFiles.populationTangentModulus = string(filename);
    localClose(figureHandle, config);
end

if localGetLogical(config, "includeZeroReferenceDiagnostics", false)
    processedIndices = find([records.status] == "processed");
    if ~isempty(processedIndices)
        figureHandle = figure("Visible", "off", "Color", "w", ...
            "Position", [100 100 1200 780]);
        columnCount = min(3, numel(processedIndices));
        rowCount = ceil(numel(processedIndices) / columnCount);
        tiledlayout(figureHandle, rowCount, columnCount, ...
            "TileSpacing", "compact", "Padding", "loose");
        for outputIndex = 1:numel(processedIndices)
            record = records(processedIndices(outputIndex));
            specimen = record.specimen;
            axesHandle = nexttile;
            hold(axesHandle, "on");
            raw = specimen.processed.raw;
            plot(axesHandle, raw.displacement, raw.force, ...
                "LineWidth", 1.0, "DisplayName", "Selected raw data");
            if isfield(specimen.processed, "zeroReference")
                reference = specimen.processed.zeroReference;
                markerIndex = reference.inputIndex;
                if markerIndex >= 1 && markerIndex <= numel(raw.force)
                    plot(axesHandle, raw.displacement(markerIndex), ...
                        raw.force(markerIndex), "o", "MarkerSize", 6, ...
                        "LineWidth", 1.1, "DisplayName", "Mechanical zero");
                end
            end
            xlabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
                "Displacement", units.displacement));
            ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
                "Force", units.force));
            title(axesHandle, record.specimenId, "Interpreter", "none");
            grid(axesHandle, "on");
            box(axesHandle, "on");
        end
        sgtitle(figureHandle, studyTitle + " — zero-reference diagnostics", ...
            "Interpreter", "none");
        filename = fullfile(folder, "zero_reference_diagnostics." + format);
        exportgraphics(figureHandle, filename, ...
            "Resolution", config.figureResolution);
        outputFiles.zeroReferenceDiagnostics = string(filename);
        localClose(figureHandle, config);
    end
end
end

function name = localStressName(study)
name = "Nominal stress, P";
if ~isfield(study, "config") || ...
        ~isfield(study.config, "datasetAnalysis") || ...
        ~isfield(study.config.datasetAnalysis, "processingConfig") || ...
        ~isfield(study.config.datasetAnalysis.processingConfig, "mechanics")
    return;
end
mechanicsConfig = study.config.datasetAnalysis.processingConfig.mechanics;
if isfield(mechanicsConfig, "stressMeasure") && ...
        lower(string(mechanicsConfig.stressMeasure)) == "true"
    name = "True stress, \sigma";
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
