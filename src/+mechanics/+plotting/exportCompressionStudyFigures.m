function files = exportCompressionStudyFigures(study, config)
%EXPORTCOMPRESSIONSTUDYFIGURES Export compression-study report figures.
arguments
    study (1,1) struct
    config (1,1) struct = mechanics.config.compressionStudyReportConfig()
end

if isfield(study, "analysis") && isfield(study.analysis, "records")
    files = localPopulationFigures(study, config);
else
    files = localSpecimenFigures(study, config);
end
end

function files = localPopulationFigures(study, config)
folder = localFolder(config);
format = lower(string(config.figureFormat));
files = struct();
records = study.analysis.records;
processedIndices = find(string({records.status}) == "processed");
units = mechanics.plotting.resolveStudyUnits(records);
strainDisplayUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "deformation", units.strain);
stressDisplayUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "stress", units.stress);
strainLabel = mechanics.plotting.formatUnitLabel( ...
    "Compression engineering strain magnitude", strainDisplayUnit);
stressLabel = mechanics.plotting.formatUnitLabel( ...
    "Compression nominal stress magnitude", stressDisplayUnit);
modulusLabel = mechanics.plotting.formatUnitLabel( ...
    "Tangent modulus", stressDisplayUnit);
displacementLabel = mechanics.plotting.formatUnitLabel( ...
    "Compression displacement magnitude", units.displacement);
forceLabel = mechanics.plotting.formatUnitLabel( ...
    "Compression force magnitude", units.force);

if config.includeIndividualCurves
    fig = localFigure(); ax = axes(fig); hold(ax, "on");
    for index = processedIndices(:)'
        specimen = records(index).specimen;
        plot(ax, -specimen.processed.strain, -specimen.processed.stress, ...
            "LineWidth", 1.1, "DisplayName", char(records(index).specimenId));
    end
    xlabel(ax, strainLabel);
    ylabel(ax, stressLabel);
    title(ax, "Individual responses");
    grid(ax, "on"); box(ax, "on"); legend(ax, "Location", "best", "Interpreter", "none");
    files.individualCurves = localExport(fig, folder, "individual_curves", format, config);
end

if config.includePopulationCurve && study.populationStatus == "completed"
    curves = study.population.curves;
    order = numel(curves.strain):-1:1;
    x = -curves.strain(order);
    fig = localFigure(); ax = axes(fig); hold(ax, "on");
    for index = 1:size(curves.stressMatrix, 2)
        plot(ax, x, -curves.stressMatrix(order, index), ...
            "LineWidth", 0.65, "HandleVisibility", "off");
    end
    if all(isfinite(curves.confidenceLower)) && all(isfinite(curves.confidenceUpper))
        confidenceLower = -curves.confidenceUpper(order);
        confidenceUpper = -curves.confidenceLower(order);
        fill(ax, [x; flipud(x)], ...
            [confidenceLower; flipud(confidenceUpper)], [0.85 0.85 0.85], ...
            "EdgeColor", "none", "DisplayName", "Bootstrap confidence interval");
    end
    if isfield(curves, "centralStress")
        central = curves.centralStress;
    else
        central = curves.meanStress;
    end
    plot(ax, x, -central(order), "LineWidth", 2.1, ...
        "DisplayName", char(string(curves.centralStatistic) + " stress"));
    xlabel(ax, strainLabel);
    ylabel(ax, stressLabel);
    title(ax, "Population response");
    grid(ax, "on"); box(ax, "on"); legend(ax, "Location", "northwest");
    files.populationCurve = localExport(fig, folder, "population_curve", format, config);
end

if config.includeTangentModulus
    fig = localFigure(); ax = axes(fig); hold(ax, "on"); plotted = false;
    summaryRangeForDisplay = [];
    for index = processedIndices(:)'
        tangent = records(index).specimen.analysis.tangentModulus;
        summaryValue = localTangentSummaryValue( ...
            study.analysis.summary, records(index).specimenId, tangent);
        displayName = string(records(index).specimenId);
        if isfinite(summaryValue)
            displayName = displayName + sprintf( ...
                " — summary %.4g %s", summaryValue, stressDisplayUnit);
        end
        curveHandle = plot(ax, -tangent.strain, tangent.tangentModulusForPlot, ...
            "LineWidth", 1.0, "DisplayName", char(displayName));
        if isfield(tangent, "summaryStrainRange") && ...
                numel(tangent.summaryStrainRange) == 2
            displayRange = sort(-double(tangent.summaryStrainRange(:)'));
            if isempty(summaryRangeForDisplay)
                summaryRangeForDisplay = displayRange;
            end
            if isfinite(summaryValue)
                plot(ax, displayRange, [summaryValue, summaryValue], "--", ...
                    "Color", curveHandle.Color, "LineWidth", 1.4, ...
                    "HandleVisibility", "off");
            end
        end
        plotted = true;
    end
    if plotted
        if numel(summaryRangeForDisplay) == 2
            xline(ax, summaryRangeForDisplay(1), "--", "Summary interval", ...
                "HandleVisibility", "off", "LabelOrientation", "aligned", ...
                "LabelVerticalAlignment", "middle");
            xline(ax, summaryRangeForDisplay(2), "--", "HandleVisibility", "off");
        end
        xlabel(ax, strainLabel);
        ylabel(ax, modulusLabel);
        title(ax, "Individual tangent modulus");
        grid(ax, "on"); box(ax, "on"); legend(ax, "Location", "best", "Interpreter", "none");
        files.tangentModulus = localExport(fig, folder, "tangent_modulus", format, config);
    else
        localClose(fig, config);
    end
end

if config.includePopulationTangentModulus && study.populationStatus == "completed" && ...
        isfield(study.population, "tangentModulusStatus") && ...
        study.population.tangentModulusStatus == "completed"
    tangent = study.population.tangentModulus;
    order = numel(tangent.strain):-1:1;
    x = -tangent.strain(order);
    fig = localFigure(); ax = axes(fig); hold(ax, "on");
    for index = 1:size(tangent.modulusMatrix, 2)
        visibility = "off";
        displayName = "";
        if index == 1
            visibility = "on";
            displayName = "Individual specimens";
        end
        plot(ax, x, tangent.modulusMatrix(order, index), ...
            "LineWidth", 0.65, "Color", [0.65 0.65 0.65], ...
            "HandleVisibility", visibility, "DisplayName", displayName);
    end
    if all(isfinite(tangent.confidenceLower)) && all(isfinite(tangent.confidenceUpper))
        fill(ax, [x; flipud(x)], ...
            [tangent.confidenceLower(order); flipud(tangent.confidenceUpper(order))], ...
            [0.85 0.85 0.85], "EdgeColor", "none", ...
            "DisplayName", "Bootstrap confidence interval");
    end
    plot(ax, x, tangent.centralModulus(order), "LineWidth", 2.1, ...
        "DisplayName", char(string(tangent.centralStatistic) + " tangent modulus"));
    [summaryRange, annotationCount] = localPopulationTangentSummary( ...
        ax, tangent, stressDisplayUnit);
    if isfield(tangent, "specimenCountByPoint")
        mechanics.plotting.markPopulationSupportChanges( ...
            ax, x, tangent.specimenCountByPoint(order));
    end
    xlabel(ax, strainLabel);
    ylabel(ax, modulusLabel);
    title(ax, "Population tangent modulus");
    grid(ax, "on"); box(ax, "on"); legend(ax, "Location", "best");
    fig.UserData.centralStatistic = string(tangent.centralStatistic);
    fig.UserData.summaryRange = summaryRange;
    fig.UserData.summaryRangeMode = localSummaryField( ...
        tangent, "rangeMode", "unavailable");
    fig.UserData.summaryValue = localSummaryField(tangent, "value", NaN);
    fig.UserData.annotationCount = annotationCount;
    files.populationTangentModulus = localExport(fig, folder, ...
        "population_tangent_modulus", format, config);
end

if localGetLogical(config, "includeSelectedModelParameters", true) && ...
        study.populationStatus == "completed" && ...
        isfield(study.population, "modelParameters") && ...
        isfield(study.population.modelParameters, "values") && ...
        ~isempty(study.population.modelParameters.values)
    fig = mechanics.plotting.plotSelectedParameterPopulation( ...
        study.population.modelParameters);
    fig.Visible = "off";
    files.selectedModelParameters = localExport( ...
        fig, folder, "selected_model_parameters", format, config);
end

if localGetLogical(config, "includeInitialShearModulus", true) && ...
        study.populationStatus == "completed" && ...
        isfield(study.population, "modelParameters") && ...
        isfield(study.population.modelParameters, "initialShearModulus") && ...
        ~isempty(study.population.modelParameters.initialShearModulus.values)
    fig = mechanics.plotting.plotInitialShearModulusPopulation( ...
        study.population.modelParameters, stressDisplayUnit);
    fig.Visible = "off";
    files.initialShearModulus = localExport( ...
        fig, folder, "initial_shear_modulus", format, config);
end

if config.includeCycleDiagnostics && ~isempty(processedIndices)
    columnCount = min(2, numel(processedIndices));
    rowCount = ceil(numel(processedIndices) / columnCount);
    fig = figure("Visible", "off", "Color", "w", "Position", [100 100 1200 800]);
    tiledlayout(fig, rowCount, columnCount, "TileSpacing", "compact", "Padding", "loose");
    for outputIndex = 1:numel(processedIndices)
        record = records(processedIndices(outputIndex));
        specimen = record.specimen;
        ax = nexttile; hold(ax, "on");
        plot(ax, specimen.fullCycleRaw.displacement, specimen.fullCycleRaw.force, ...
            "LineWidth", 1.0, "DisplayName", "Selected full cycle");
        plot(ax, -specimen.processed.displacement, -specimen.processed.force, ...
            "LineWidth", 1.4, "DisplayName", "Processed loading branch");
        xlabel(ax, displacementLabel);
        ylabel(ax, forceLabel);
        title(ax, record.specimenId, "Interpreter", "none"); grid(ax, "on"); box(ax, "on");
    end
    sgtitle(fig, "Cycle diagnostics");
    files.cycleDiagnostics = localExport(fig, folder, "cycle_diagnostics", format, config);
end
end

function files = localSpecimenFigures(study, config)
folder = localFolder(config); format = lower(string(config.figureFormat)); files = struct();
specimen = study.specimen;
records = struct("status", "processed", "specimen", specimen);
units = mechanics.plotting.resolveStudyUnits(records);
strainDisplayUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "deformation", units.strain);
stressDisplayUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "stress", units.stress);
displacementLabel = mechanics.plotting.formatUnitLabel( ...
    "Compression displacement", units.displacement);
forceLabel = mechanics.plotting.formatUnitLabel( ...
    "Compression force", units.force);
strainLabel = mechanics.plotting.formatUnitLabel( ...
    "Compression strain", strainDisplayUnit);
stressLabel = mechanics.plotting.formatUnitLabel( ...
    "Compression stress", stressDisplayUnit);
modulusLabel = mechanics.plotting.formatUnitLabel( ...
    "Tangent modulus", stressDisplayUnit);
if config.includeCycleOverview
    fig = localFigure(); ax = axes(fig); hold(ax, "on"); cycleRaw = specimen.fullCycleRaw;
    peakIndex = study.cycle.loadingEndIndex - study.cycle.cycleStartIndex + 1;
    plot(ax, cycleRaw.displacement, cycleRaw.force, "LineWidth", 1.2, "DisplayName", "Selected full cycle");
    plot(ax, cycleRaw.displacement(1:peakIndex), cycleRaw.force(1:peakIndex), ...
        "LineWidth", 1.8, "DisplayName", "Loading branch");
    plot(ax, cycleRaw.displacement(peakIndex:end), cycleRaw.force(peakIndex:end), ...
        "LineWidth", 1.8, "DisplayName", "Unloading branch");
    xlabel(ax, displacementLabel);
    ylabel(ax, forceLabel);
    title(ax, "Selected compression cycle");
    grid(ax, "on"); box(ax, "on"); legend(ax, "Location", "best");
    files.cycleOverview = localExport(fig, folder, "compression_cycle", format, config);
end
if config.includeSelectedBranch
    fig = localFigure(); ax = axes(fig);
    plot(ax, specimen.processed.strain, specimen.processed.stress, "LineWidth", 1.5);
    xlabel(ax, strainLabel);
    ylabel(ax, stressLabel);
    title(ax, "Selected loading response");
    grid(ax, "on"); box(ax, "on");
    files.selectedBranch = localExport(fig, folder, "compression_response", format, config);
end
if config.includeTangentModulus
    modulus = specimen.analysis.tangentModulus; fig = localFigure(); ax = axes(fig); hold(ax, "on");
    summaryValue = localTangentSummaryValue(table(), "", modulus);
    curveHandle = plot(ax, modulus.strain, modulus.tangentModulusForPlot, "LineWidth", 1.4);
    xline(ax, modulus.summaryStrainRange(1), "--", "Summary interval");
    xline(ax, modulus.summaryStrainRange(2), "--", "HandleVisibility", "off");
    if isfinite(summaryValue)
        plot(ax, sort(double(modulus.summaryStrainRange(:)')), ...
            [summaryValue, summaryValue], "--", "Color", curveHandle.Color, ...
            "LineWidth", 1.4, "HandleVisibility", "off");
    end
    xlabel(ax, strainLabel);
    ylabel(ax, modulusLabel);
    title(ax, "Individual tangent modulus");
    grid(ax, "on"); box(ax, "on");
    files.tangentModulus = localExport(fig, folder, "compression_tangent_modulus", format, config);
end
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

function folder = localFolder(config)
folder = string(config.outputFolder); if ~isfolder(folder), mkdir(folder); end
end
function fig = localFigure()
fig = figure("Visible", "off", "Color", "w", "Position", [100 100 1050 760]);
end
function filename = localExport(fig, folder, name, format, config)
filename = mechanics.plotting.exportFigureFiles( ...
    fig, folder, string(name), string(format), config.figureResolution);
localClose(fig, config);
end
function [summaryRange, annotationCount] = localPopulationTangentSummary( ...
        axesHandle, tangent, stressUnit)
summaryRange = [NaN, NaN];
annotationCount = 0;
if ~isfield(tangent, "summary") || isempty(tangent.summary)
    return;
end
summary = tangent.summary;
summaryRange = sort(-double(summary.displayRange(:)'));
if all(isfinite(summaryRange))
    xline(axesHandle, summaryRange(1), "--", "Summary interval", ...
        "DisplayName", "Summary interval", "LabelOrientation", "aligned", ...
        "LabelVerticalAlignment", "middle");
    xline(axesHandle, summaryRange(2), "--", "HandleVisibility", "off");
end
if ~isfinite(summary.value)
    return;
end
label = sprintf('%s summary tangent modulus = %.4g %s', ...
    localStatisticLabel(summary.centralStatistic), summary.value, stressUnit);
xLimits = xlim(axesHandle);
[xPosition, horizontalAlignment] = localSummaryAnnotationPosition( ...
    summaryRange, xLimits);
yLimits = ylim(axesHandle);
yPosition = yLimits(1) + 0.92 .* diff(yLimits);
text(axesHandle, xPosition, yPosition, label, ...
    "HorizontalAlignment", horizontalAlignment, "VerticalAlignment", "top", ...
    "Interpreter", "none", "BackgroundColor", "white", "Margin", 4);
annotationCount = 1;
end

function [position, alignment] = localSummaryAnnotationPosition(range, limits)
padding = 0.01 .* diff(limits);
if all(isfinite(range)) && range(2) <= mean(limits)
    position = range(1) + padding;
    alignment = "left";
elseif all(isfinite(range))
    position = range(2) - padding;
    alignment = "right";
else
    position = limits(2) - padding;
    alignment = "right";
end
end

function label = localStatisticLabel(value)
value = lower(string(value));
label = upper(extractBefore(value, 2)) + extractAfter(value, 1);
end

function value = localSummaryField(tangent, fieldName, defaultValue)
value = defaultValue;
if isfield(tangent, "summary") && isfield(tangent.summary, fieldName)
    value = tangent.summary.(fieldName);
end
end
function value = localGetLogical(config, fieldName, defaultValue)
if isfield(config, fieldName), value = logical(config.(fieldName)); else, value = logical(defaultValue); end
end
function localClose(fig, config)
if config.closeFiguresAfterExport && isgraphics(fig), close(fig); end
end
