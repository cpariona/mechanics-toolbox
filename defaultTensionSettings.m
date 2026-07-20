function settings = defaultTensionSettings()
% Defines default settings for tension test processing.
%
% Inputs:
%   None.
%
% Outputs:
%   settings - Structure with processing, smoothing, modulus, and bootstrap settings.

    settings.zero_displacement_at_start = false;
    settings.zero_force_at_start = false;

    settings.window_mode = "full";
    settings.manual_start_idx = 1;
    settings.manual_end_idx = Inf;
    settings.zero_window_start = false;
    settings.end_trim_samples = 0;

    settings.calibrated_length = 25;

    settings.i_samples = 7;
    settings.E_window_samples = 200;

    settings.n_bootstrap = 10000;
    settings.ci_level = 95;

    settings.smooth_stress_strain = true;
    settings.smooth_frame_length = 21;
    settings.smooth_poly_order = 3;

    settings.smooth_E_t_for_plot = true;
    settings.E_t_plot_smooth_frame_length = 151;
end