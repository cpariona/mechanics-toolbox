function [E_t, E_t_plot, E_median, strain_smooth, stress_smooth] = calculateTangentialModulus(strain, stress, settings)
% Calculates tangent modulus from stress-strain data.
% Optionally smooths stress-strain once before derivative calculation.
% Creates an extra smoothed modulus curve only for plotting.
%
% Inputs:
%   strain   - Strain vector.
%   stress   - Stress vector.
%   settings - Structure with smoothing and modulus settings.
%
% Outputs:
%   E_t           - Tangent modulus used for analysis.
%   E_t_plot      - Smoothed tangent modulus used only for plotting.
%   E_median      - Median modulus within selected modulus window.
%   strain_smooth - Strain used for derivative and plotting.
%   stress_smooth - Stress used for derivative and plotting.

    strain = strain(:);
    stress = stress(:);

    if isfield(settings, 'smooth_stress_strain') && settings.smooth_stress_strain
        strain_smooth = smoothMechanicalVector( ...
            strain, settings.smooth_frame_length, settings.smooth_poly_order);

        stress_smooth = smoothMechanicalVector( ...
            stress, settings.smooth_frame_length, settings.smooth_poly_order);
    else
        strain_smooth = strain;
        stress_smooth = stress;
    end

    E_t = gradient(stress_smooth) ./ gradient(strain_smooth);

    idx_end_modulus = min(settings.i_samples + settings.E_window_samples - 1, length(E_t));

    if idx_end_modulus > settings.i_samples
        E_median = median(E_t(settings.i_samples:idx_end_modulus), 'omitnan');
    else
        E_median = NaN;
    end

    if isfield(settings, 'smooth_E_t_for_plot') && settings.smooth_E_t_for_plot
        E_t_plot = smoothMechanicalVector( ...
            E_t, settings.E_t_plot_smooth_frame_length, settings.smooth_poly_order);
    else
        E_t_plot = E_t;
    end
end