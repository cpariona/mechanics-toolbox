function plotMechanicalSpecimenCurves(experiment, saveFolder)
% Plots individual stress-strain and tangent modulus curves.
% Generates one figure per experimental condition.
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

        ax1 = subplot(2,1,1); hold(ax1, 'on');
        ax1.YRuler.Exponent = 0;
        xlabel(ax1, labels.strain);
        ylabel(ax1, labels.stress);
        title(ax1, [labels.testName ' stress-strain curve ' condition.name]);

        ax2 = subplot(2,1,2); hold(ax2, 'on');
        xlabel(ax2, labels.strain);
        ylabel(ax2, labels.modulus);
        title(ax2, [labels.testName ' modulus ' condition.name]);

        for k = 1:numel(condition.specimens)

            specimen = condition.specimens(k);

            plot_strain = specimen.strain_smooth;
            plot_stress = specimen.stress_smooth;
            plot_E_t = specimen.E_t_plot;

            plot(ax1, plot_strain, plot_stress, ...
                'DisplayName', specimen.label);

            plot(ax2, plot_strain, plot_E_t, ...
                'DisplayName', specimen.label);

            idx_end_modulus = min(settings.i_samples + settings.E_window_samples - 1, length(plot_E_t));

            if idx_end_modulus > settings.i_samples
                plot(ax2, plot_strain(settings.i_samples:idx_end_modulus), ...
                          plot_E_t(settings.i_samples:idx_end_modulus), ...
                          'LineWidth', 2.5, ...
                          'HandleVisibility', 'off');
            end
        end

        legend(ax1, 'show', 'Location', 'best');
        legend(ax2, 'show', 'Location', 'best');

        saveFigureBothFormats(figHandle, saveFolder, ...
            [experiment.testType '_individual_curves_' sanitizeFileName(condition.name)]);
    end
end