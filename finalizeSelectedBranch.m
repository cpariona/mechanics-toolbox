function [strain, stress] = finalizeSelectedBranch(strain, stress, settings)
% Applies final zeroing and trimming to a selected curve branch.
%
% Inputs:
%   strain   - Selected strain vector.
%   stress   - Selected stress vector.
%   settings - Structure with zeroing and trimming settings.
%
% Outputs:
%   strain - Final strain vector.
%   stress - Final stress vector.

    if settings.zero_window_start
        strain = strain - strain(1);
        stress = stress - stress(1);
    end

    if settings.end_trim_samples > 0 && length(strain) > settings.end_trim_samples
        strain = strain(1:end-settings.end_trim_samples);
        stress = stress(1:end-settings.end_trim_samples);
    end
end