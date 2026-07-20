function [median_curve, lower_CI, upper_CI] = bootstrapMedianCI(data, n_bootstrap, ci_level)
% Computes median and bootstrap confidence intervals.
% Data are assumed to be arranged as rows = points and columns = specimens.
%
% Inputs:
%   data        - Input data matrix or vector.
%   n_bootstrap - Number of bootstrap resamples.
%   ci_level    - Confidence interval level in percent.
%
% Outputs:
%   median_curve - Median values.
%   lower_CI     - Lower confidence interval.
%   upper_CI     - Upper confidence interval.

    if isvector(data)
        data = data(:)';
    end

    median_curve = median(data, 2, 'omitnan');

    n_obs = size(data, 2);

    if n_obs < 2
        lower_CI = median_curve;
        upper_CI = median_curve;
        return;
    end

    alpha = (100 - ci_level) / 2;

    boot_stats = bootstrp( ...
        n_bootstrap, ...
        @(idx) median(data(:, idx), 2, 'omitnan')', ...
        1:n_obs);

    lower_CI = prctile(boot_stats, alpha, 1)';
    upper_CI = prctile(boot_stats, 100 - alpha, 1)';
end