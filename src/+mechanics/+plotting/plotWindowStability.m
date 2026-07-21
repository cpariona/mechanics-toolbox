function figHandle = plotWindowStability(study)
%PLOTWINDOWSTABILITY Plot fitted parameter values across deformation windows.
arguments
    study (1,1) struct
end

modelNames = study.modelNames(:);
nModels = numel(modelNames);
figHandle = figure("Color", "w");
layout = tiledlayout(figHandle, nModels, 1, ...
    "TileSpacing", "compact", "Padding", "compact");

for iModel = 1:nModels
    nexttile(layout);
    records = study.records([study.records.modelName] == modelNames(iModel));
    successful = records([records.succeeded]);

    if isempty(successful)
        text(0.5, 0.5, "No successful fits", ...
            "HorizontalAlignment", "center");
        axis off
        title(modelNames(iModel), "Interpreter", "none");
        continue;
    end

    fractions = [successful.windowFraction]';
    parameterMatrix = vertcat(successful.fitResult);
    parameterMatrix = vertcat(parameterMatrix.parameters);
    parameterNames = successful(1).fitResult.parameterNames;

    plot(fractions, parameterMatrix, "-o", "LineWidth", 1.2);
    xlabel("Fraction of deformation range");
    ylabel("Fitted parameter");
    title(modelNames(iModel), "Interpreter", "none");
    legend(parameterNames, "Location", "best", "Interpreter", "none");
    grid on
    box on
end
end
