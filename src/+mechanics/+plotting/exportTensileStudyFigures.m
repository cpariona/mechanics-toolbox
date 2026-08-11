function outputFiles = exportTensileStudyFigures(study, config)
%EXPORTTENSILESTUDYFIGURES Export standard figures for a tensile study.
arguments
    study (1,1) struct
    config (1,1) struct = mechanics.config.tensileStudyReportConfig()
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

outputFiles = struct();
format = lower(string(config.figureFormat));
records = study.analysis.records;
units = mechanics.plotting.resolveStudyUnits(records);
strainDisplayUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "deformation", units.strain);
stressDisplayUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "stress", units.stress);
studyTitle = localStudyTitle(study, config);
strainLabel = mechanics.plotting.formatUnitLabel( ...
    "Engineering strain, \epsilon", strainDisplayUnit);
stressLabel = mechanics.plotting.formatUnitLabel( ...
    localStressName(study), stressDisplayUnit);
modulusLabel = mechanics.plotting.formatUnitLabel( ...
    "Tangent modulus", stressDisplayUnit);

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
    outputFiles.individualCurves = localExport( ...
        figureHandle, folder, "individual_curves", format, config);
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
    outputFiles.populationCurve = localExport( ...
        figureHandle, folder, "population_curve", format, config);
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
        "Peak nominal stress", stressDisplayUnit));
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
    outputFiles.peakMetrics = localExport( ...
        figureHandle, folder, "peak_metrics", format, config);
end

if config.includeTangentModulus
    figureHandle = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1050 760]);
    axesHandle = axes(figureHandle);
    hold(axesHandle, "on");
    plotted = false;
    summaryRangeForDisplay = [];
    for index = 1:numel(records)
        if records(index).status ~= "processed" || ...
                ~isfield(records(index).specimen, "analysis") || ...
                ~isfield(records(index).specimen.analysis, "tangentModulus")
            continue;
        end
        modulus = records(index).specimen.analysis.tangentModulus;
        summaryValue = localTangentSummaryValue( ...
            study.analysis.summary, records(index).specimenId, modulus);
        displayName = string(records(index).specimenId);
        if isfinite(summaryValue)
            displayName = displayName + sprintf( ...
                " — summary %.4g %s", summaryValue, stressDisplayUnit);
        end
        curveHandle = plot(axesHandle, modulus.strain, ...
            modulus.tangentModulusForPlot, "LineWidth", 1.0, ...
            "DisplayName", char(displayName));
        if isfield(modulus, "summaryStrainRange") && ...
                numel(modulus.summaryStrainRange) == 2
            summaryRange = sort(double(modulus.summaryStrainRange(:)'));
            if isempty(summaryRangeForDisplay)
                summaryRangeForDisplay = summaryRange;
            end
            if isfinite(summaryValue)
                plot(axesHandle, summaryRange, ...
                    [summaryValue, summaryValue], "--", ...
                    "Color", curveHandle.Color, "LineWidth", 1.4, ...
                    "HandleVisibility", "off");
            end
        end
        plotted = true;
    end
    if plotted
        if numel(summaryRangeForDisplay) == 2
            xline(axesHandle, summaryRangeForDisplay(1), "--", ...
                "Summary interval", "HandleVisibility", "off", ...
                "LabelOrientation", "aligned", ...
                "LabelVerticalAlignment", "middle");
            xline(axesHandle, summaryRangeForDisplay(2), "--", ...
                "HandleVisibility", "off");
        end
        xlabel(axesHandle, strainLabel);
        ylabel(axesHandle, modulusLabel);
        title(axesHandle, studyTitle + " — tangent modulus", ...
            "Interpreter", "none");
        grid(axesHandle, "on");
        box(axesHandle, "on");
        legend(axesHandle, "Location", "southwest", "Interpreter", "none");
        outputFiles.tangentModulus = localExport( ...
            figureHandle, folder, "tangent_modulus", format, config);
    else
        localClose(figureHandle, config);
    end
end

if config.includePopulationTangentModulus && ...
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
    if isfield(tangent, "specimenCountByPoint")
        mechanics.plotting.markPopulationSupportChanges( ...
            axesHandle, tangent.strain, tangent.specimenCountByPoint);
    end
    xlabel(axesHandle, strainLabel);
    ylabel(axesHandle, modulusLabel);
    title(axesHandle, studyTitle + " — population tangent modulus", ...
        "Interpreter", "none");
    grid(axesHandle, "on");
    box(axesHandle, "on");
    legend(axesHandle, "Location", "northwest");
    outputFiles.populationTangentModulus = localExport( ...
        figureHandle, folder, "population_tangent_modulus", format, config);
end

if localGetLogical(config, "includeSelectedModelParameters", true) && ...
        isfield(study, "population") && ...
        isfield(study.population, "modelParameters") && ...
        isfield(study.population.modelParameters, "values") && ...
        ~isempty(study.population.modelParameters.values)
    figureHandle = mechanics.plotting.plotSelectedParameterPopulation( ...
        study.population.modelParameters);
    figureHandle.Visible = "off";
    outputFiles.selectedModelParameters = localExport( ...
        figureHandle, folder, "selected_model_parameters", format, config);
end

if localGetLogical(config, "includeInitialShearModulus", true) && ...
        isfield(study, "population") && ...
        isfield(study.population, "modelParameters") && ...
        isfield(study.population.modelParameters, "initialShearModulus") && ...
        ~isempty(study.population.modelParameters.initialShearModulus.values)
    figureHandle = mechanics.plotting.plotInitialShearModulusPopulation( ...
        study.population.modelParameters);
    figureHandle.Visible = "off";
    outputFiles.initialShearModulus = localExport( ...
        figureHandle, folder, "initial_shear_modulus", format, config);
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
        halfWindow = max(1, round(double( ...
            localGetNumeric(config, "zeroReferenceDiagnosticHalfWindowPoints", 30))));
        for outputIndex = 1:numel(processedIndices)
            record = records(processedIndices(outputIndex));
            specimen = record.specimen;
            axesHandle = nexttile;
            hold(axesHandle, "on");
            raw = specimen.processed.raw;
            markerIndex = NaN;
            if isfield(specimen.processed, "zeroReference") && ...
                    isfield(specimen.processed.zeroReference, "inputIndex")
                markerIndex = double(specimen.processed.zeroReference.inputIndex);
            end
            localIndices = 1:numel(raw.force);
            if isfinite(markerIndex) && markerIndex >= 1 && ...
                    markerIndex <= numel(raw.force)
                localIndices = max(1, markerIndex-halfWindow): ...
                    min(numel(raw.force), markerIndex+halfWindow);
            end
            plot(axesHandle, raw.displacement(localIndices), ...
                raw.force(localIndices), "LineWidth", 1.0, ...
                "DisplayName", "Local raw data");
            if isfinite(markerIndex) && markerIndex >= 1 && ...
                    markerIndex <= numel(raw.force)
                plot(axesHandle, raw.displacement(markerIndex), ...
                    raw.force(markerIndex), "o", "MarkerSize", 7, ...
                    "LineWidth", 1.2, "DisplayName", "Mechanical zero");
            end
            xlabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
                "Displacement", units.displacement));
            ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
                "Force", units.force));
            title(axesHandle, record.specimenId, "Interpreter", "none");
            grid(axesHandle, "on");
            box(axesHandle, "on");
        end
        sgtitle(figureHandle, studyTitle + " — local zero-reference diagnostics", ...
            "Interpreter", "none");
        outputFiles.zeroReferenceDiagnostics = localExport( ...
            figureHandle, folder, "zero_reference_diagnostics", format, config);
    end
end
end

function filename = localExport(figureHandle, folder, baseName, format, config)
filename = mechanics.plotting.exportFigureFiles( ...
    figureHandle, folder, string(baseName), string(format), ...
    config.figureResolution);
localClose(figureHandle, config);
end

function value = localTangentSummaryValue(summary, specimenId, tangent)
value = NaN;
if isfield(tangent, "medianModulus") && isfinite(tangent.medianModulus)
    value = double(tangent.medianModulus);
    return;
end
if isempty(summary) || ...
        ~all(ismember(["SpecimenId", "MedianTangentModulus"], ...
        string(summary.Properties.VariableNames)))
    return;
end
row = find(string(summary.SpecimenId) == string(specimenId), 1, "first");
if ~isempty(row) && isfinite(summary.MedianTangentModulus(row))
    value = double(summary.MedianTangentModulus(row));
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

function value = localGetNumeric(config, fieldName, defaultValue)
if isfield(config, fieldName)
    value = double(config.(fieldName));
else
    value = double(defaultValue);
end
end

function localClose(figureHandle, config)
if config.closeFiguresAfterExport && isgraphics(figureHandle)
    close(figureHandle);
end
end
