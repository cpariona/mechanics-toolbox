function condition = summarizeMechanicalCondition(condition, all_strain, all_stress, all_E_t, all_E_t_plot, E_all, settings)
% Summarizes all specimens within one mechanical test condition.
% Interpolates curves to a common strain axis and computes median curves
% with bootstrap confidence intervals.
%
% Inputs:
%   condition    - Condition structure with specimen data.
%   all_strain   - Cell array with strain vectors used for plotting and summaries.
%   all_stress   - Cell array with stress vectors used for plotting and summaries.
%   all_E_t      - Cell array with tangent modulus vectors used for analysis.
%   all_E_t_plot - Cell array with smoothed tangent modulus vectors used for plotting.
%   E_all        - Vector with specimen-level modulus values.
%   settings     - Structure with bootstrap settings.
%
% Outputs:
%   condition - Updated condition structure with summary data.

    min_len = min(cellfun(@length, all_strain));
    max_common_strain = min(cellfun(@max, all_strain));

    common_strain = linspace(0, max_common_strain, min_len);

    nSpecimens = numel(all_strain);

    interp_stress = NaN(numel(common_strain), nSpecimens);
    interp_E_t = NaN(numel(common_strain), nSpecimens);
    interp_E_t_plot = NaN(numel(common_strain), nSpecimens);

    for k = 1:nSpecimens

        [strain_u, idx_u] = unique(all_strain{k}, 'stable');

        interp_stress(:, k) = interp1( ...
            strain_u, all_stress{k}(idx_u), common_strain, 'linear', NaN);

        interp_E_t(:, k) = interp1( ...
            strain_u, all_E_t{k}(idx_u), common_strain, 'linear', NaN);

        interp_E_t_plot(:, k) = interp1( ...
            strain_u, all_E_t_plot{k}(idx_u), common_strain, 'linear', NaN);
    end

    [median_stress, lower_stress, upper_stress] = bootstrapMedianCI( ...
        interp_stress, settings.n_bootstrap, settings.ci_level);

    [median_E_t, lower_E_t, upper_E_t] = bootstrapMedianCI( ...
        interp_E_t, settings.n_bootstrap, settings.ci_level);

    [median_E_t_plot, lower_E_t_plot, upper_E_t_plot] = bootstrapMedianCI( ...
        interp_E_t_plot, settings.n_bootstrap, settings.ci_level);

    [E_median, E_lower_CI, E_upper_CI] = bootstrapMedianCI( ...
        E_all, settings.n_bootstrap, settings.ci_level);

    condition.common_strain = common_strain;

    condition.interp_stress = interp_stress;
    condition.interp_E_t = interp_E_t;
    condition.interp_E_t_plot = interp_E_t_plot;

    condition.median_stress = median_stress;
    condition.lower_stress_CI = lower_stress;
    condition.upper_stress_CI = upper_stress;

    condition.median_E_t = median_E_t;
    condition.lower_E_t_CI = lower_E_t;
    condition.upper_E_t_CI = upper_E_t;

    condition.median_E_t_plot = median_E_t_plot;
    condition.lower_E_t_plot_CI = lower_E_t_plot;
    condition.upper_E_t_plot_CI = upper_E_t_plot;

    condition.E_all = E_all;
    condition.E_median = E_median;
    condition.E_lower_CI = E_lower_CI;
    condition.E_upper_CI = E_upper_CI;
end