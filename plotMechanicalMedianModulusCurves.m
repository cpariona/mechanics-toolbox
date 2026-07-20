function plotMechanicalMedianModulusCurves(experiment, saveFolder)
% Plots median tangent modulus curves with bootstrap confidence intervals.
% Uses plot-smoothed modulus curves only for visualization.
%
% Inputs:
%   experiment - Structure containing processed mechanical test data.
%   saveFolder - Folder where figures are saved.
%
% Outputs:
%   Saves .fig and .tif files for each condition.

    ensureFolderExists(saveFolder);

    settings = experiment.settings;
    labels = experiment.labels;

    for f = 1:numel(experiment.conditions)

        condition = experiment.conditions(f);
        figHandle = createWhiteFigure();
        hold on;

        title(['Median ' lower(labels.testName) ' modulus + bootstrap ' ...
            num2str(settings.ci_level) '% CI (' condition.name ')']);

        xlabel(labels.strain);
        ylabel(labels.modulus);

        fill([condition.common_strain fliplr(condition.common_strain)], ...
             [condition.upper_E_t_plot_CI' fliplr(condition.lower_E_t_plot_CI')], ...
             [0.8 0.8 1], ...
             'FaceAlpha', 0.4, ...
             'EdgeColor', 'none');

        plot(condition.common_strain, condition.median_E_t_plot, ...
             'b', 'LineWidth', 2, 'DisplayName', 'Median');

        idx_end_modulus = min(settings.i_samples + settings.E_window_samples - 1, ...
            length(condition.common_strain));

        if idx_end_modulus > settings.i_samples
            plot(condition.common_strain(settings.i_samples:idx_end_modulus), ...
                 condition.median_E_t_plot(settings.i_samples:idx_end_modulus), ...
                 'b--', ...
                 'LineWidth', 2.5, ...
                 'DisplayName', 'Modulus interval');
        end

        legend([num2str(settings.ci_level) '% bootstrap CI'], ...
            'Median', 'Modulus interval', 'Location', 'best');

        hold off;

        saveFigureBothFormats(figHandle, saveFolder, ...
            [experiment.testType '_median_modulus_' sanitizeFileName(condition.name)]);
    end
end