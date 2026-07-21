function files = exportConstitutiveStudyFigures(batch, population, inference, config)
%EXPORTCONSTITUTIVESTUDYFIGURES Export final study summary figures.
arguments
    batch (1,1) struct
    population (1,1) struct
    inference (1,1) struct
    config (1,1) struct = mechanics.config.constitutiveStudyReportConfig()
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end
format = lower(string(config.figureFormat));
files = struct();

if config.includeModelSelectionFigure && isfield(batch, "modelSummary") && ...
        ~isempty(batch.modelSummary)
    summary = batch.modelSummary;
    fig = figure("Visible", "off", "Color", "w");
    labels = categorical(summary.ModelName);
    labels = reordercats(labels, cellstr(summary.ModelName));
    bar(labels, summary.SelectionFraction);
    ylim([0 1]);
    ylabel("Selection fraction");
    title("Selected constitutive models");
    grid on;
    box on;
    filename = fullfile(folder, "model_selection." + format);
    exportgraphics(fig, filename, "Resolution", config.figureResolution);
    files.modelSelection = string(filename);
    localClose(fig, config);
end

if config.includeParameterFigure && isfield(population, "parameterTable") && ...
        ~isempty(population.parameterTable)
    data = population.parameterTable;
    labels = data.ModelName + ":" + data.Parameter;
    uniqueLabels = unique(labels, "stable");
    fig = figure("Visible", "off", "Color", "w");
    axesHandle = axes(fig);
    hold(axesHandle, "on");
    for index = 1:numel(uniqueLabels)
        mask = labels == uniqueLabels(index);
        x = repmat(index, nnz(mask), 1);
        scatter(axesHandle, x, data.Value(mask), 30, "filled", ...
            "DisplayName", char(uniqueLabels(index)));
    end
    xlim(axesHandle, [0.5 numel(uniqueLabels)+0.5]);
    xticks(axesHandle, 1:numel(uniqueLabels));
    xticklabels(axesHandle, cellstr(uniqueLabels));
    xtickangle(axesHandle, 30);
    ylabel(axesHandle, "Fitted parameter value");
    title(axesHandle, "Selected-model parameters by specimen");
    grid(axesHandle, "on");
    box(axesHandle, "on");
    filename = fullfile(folder, "selected_parameters." + format);
    exportgraphics(fig, filename, "Resolution", config.figureResolution);
    files.selectedParameters = string(filename);
    localClose(fig, config);
end

if config.includeInferenceFigure && isfield(inference, "comparisonTable") && ...
        ~isempty(inference.comparisonTable)
    data = inference.comparisonTable;
    valid = isfinite(data.MeanDifference) & ...
        isfinite(data.ConfidenceIntervalLower) & ...
        isfinite(data.ConfidenceIntervalUpper);
    data = data(valid,:);
    if ~isempty(data)
        labels = data.ModelName + ":" + data.Parameter + " " + ...
            data.Group1 + "-" + data.Group2;
        lowerError = data.MeanDifference - data.ConfidenceIntervalLower;
        upperError = data.ConfidenceIntervalUpper - data.MeanDifference;
        fig = figure("Visible", "off", "Color", "w");
        errorbar(1:height(data), data.MeanDifference, lowerError, upperError, ...
            "o", "LineStyle", "none", "LineWidth", 1.2);
        hold on;
        yline(0, "--");
        xlim([0.5 height(data)+0.5]);
        xticks(1:height(data));
        xticklabels(cellstr(labels));
        xtickangle(30);
        ylabel("Mean difference");
        title("Between-group parameter differences");
        grid on;
        box on;
        filename = fullfile(folder, "group_parameter_inference." + format);
        exportgraphics(fig, filename, "Resolution", config.figureResolution);
        files.groupInference = string(filename);
        localClose(fig, config);
    end
end
end

function localClose(fig, config)
if config.closeFiguresAfterExport && isgraphics(fig)
    close(fig);
end
end
