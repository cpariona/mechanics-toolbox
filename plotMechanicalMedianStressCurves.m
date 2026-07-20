function plotMechanicalMedianStressCurves(experiment, saveFolder)
% Plots median stress-strain curves with bootstrap confidence intervals.
% Generates one figure per experimental condition.
%
% Inputs:
%   experiment - Structure containing processed mechanical test data.
%   saveFolder - Folder where figures are saved.
%
% Outputs:
%   Saves .fig and .tif files for each condition.

    ensureFolderExists(saveFolder);

    labels = experiment.labels;
    ci_level = experiment.settings.ci_level;

    for f = 1:numel(experiment.conditions)

        condition = experiment.conditions(f);
        figHandle = createWhiteFigure();
        hold on;

        title(['Median ' lower(labels.testName) ' stress-strain curve + bootstrap ' ...
            num2str(ci_level) '% CI (' condition.name ')']);

        xlabel(labels.strain);
        ylabel(labels.stress);

        fill([condition.common_strain fliplr(condition.common_strain)], ...
             [condition.upper_stress_CI' fliplr(condition.lower_stress_CI')], ...
             [0.8 0.8 1], ...
             'FaceAlpha', 0.4, ...
             'EdgeColor', 'none');

        plot(condition.common_strain, condition.median_stress, ...
             'b', 'LineWidth', 2, 'DisplayName', 'Median');

        legend([num2str(ci_level) '% bootstrap CI'], 'Median', 'Location', 'best');
        hold off;

        saveFigureBothFormats(figHandle, saveFolder, ...
            [experiment.testType '_median_stress_strain_' sanitizeFileName(condition.name)]);
    end
end