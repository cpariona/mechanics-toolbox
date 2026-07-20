function experiment = processCompressionExperiment(files, ratios, specimens_list, settings)
% Processes compression experiments from raw Excel files.
% Selects the last loading branch, computes stress, strain, tangent modulus,
% median curves, and bootstrap confidence intervals.
%
% Inputs:
%   files          - Cell array with full Excel file paths.
%   ratios         - Cell array with material or condition names.
%   specimens_list - Cell array with specimen sheet names per file.
%   settings       - Structure with processing and bootstrap settings.
%
% Outputs:
%   experiment - Structure containing processed compression data.

    experiment.testType = 'Compression';
    experiment.files = files;
    experiment.ratios = ratios;
    experiment.settings = settings;
    experiment.labels = getCompressionLabels();

    conditions = repmat(conditionTemplate(), 1, numel(files));

    for f = 1:numel(files)

        data = readMechanicalExcelFile(files{f});
        resultsTbl = data{2,2};
        specimens = specimens_list{f};

        condition = conditionTemplate();
        condition.name = ratios{f};
        condition.file = files{f};
        condition.specimen_names = specimens;
        condition.specimens = repmat(specimenTemplate(), 1, numel(specimens));

        all_strain = cell(1, numel(specimens));
        all_stress = cell(1, numel(specimens));
        all_E_t = cell(1, numel(specimens));
        all_E_t_plot = cell(1, numel(specimens));
        E_all = NaN(1, numel(specimens));

        for k = 1:numel(specimens)

            sheetName = specimens{k};
            specimenLabel = sprintf('Specimen %d', k);

            geometry = getCompressionGeometry(resultsTbl, sheetName);
            specimenTbl = getSheetTable(data, sheetName);

            deformation = getTableColumn(specimenTbl, {'Deformación','Deformacion','Elongation'});
            force       = getTableColumn(specimenTbl, {'Fuerza estándar','Fuerza estandar','Standard force'});

            [strain, stress, strain_smooth, stress_smooth, E_t, E_t_plot, E_median] = ...
                processCompressionSpecimen(deformation, force, geometry, settings);

            condition.specimens(k) = struct( ...
                'sheetName', sheetName, ...
                'label', specimenLabel, ...
                'geometry', geometry, ...
                'strain', strain, ...
                'stress', stress, ...
                'strain_smooth', strain_smooth, ...
                'stress_smooth', stress_smooth, ...
                'E_t', E_t, ...
                'E_t_plot', E_t_plot, ...
                'E_median', E_median);

            all_strain{k} = strain_smooth;
            all_stress{k} = stress_smooth;
            all_E_t{k} = E_t;
            all_E_t_plot{k} = E_t_plot;
            E_all(k) = E_median;
        end

        condition = summarizeMechanicalCondition( ...
            condition, all_strain, all_stress, all_E_t, all_E_t_plot, E_all, settings);

        conditions(f) = condition;
    end

    experiment.conditions = conditions;
end

function labels = getCompressionLabels()
% Defines labels used in compression plots.
%
% Inputs:
%   None.
%
% Outputs:
%   labels - Structure with plot labels.

    labels.testName = 'Compression';
    labels.strain = 'Compressive strain [mm/mm]';
    labels.stress = 'Compressive stress [MPa]';
    labels.modulus = 'Tangential compression modulus [MPa]';
    labels.modulusSymbol = 'E_c';
end

function geometry = getCompressionGeometry(resultsTbl, sheetName)
% Gets compression specimen geometry from the results table.
%
% Inputs:
%   resultsTbl - Results table from the Excel file.
%   sheetName  - Specimen sheet name.
%
% Outputs:
%   geometry - Structure with d0, h0, and area.

    geometry.d0 = getResultValue(resultsTbl, sheetName, 'd0');
    geometry.h0 = getResultValue(resultsTbl, sheetName, 'h0');
    geometry.area = pi * geometry.d0^2 / 4;
end

function [strain, stress, strain_smooth, stress_smooth, E_t, E_t_plot, E_median] = processCompressionSpecimen(deformation, force, geometry, settings)
% Processes one compression specimen.
% Converts raw data into stress, strain, and tangent modulus.
%
% Inputs:
%   deformation - Raw deformation vector.
%   force       - Raw force vector.
%   geometry    - Structure with specimen geometry.
%   settings    - Structure with processing settings.
%
% Outputs:
%   strain        - Processed raw strain vector.
%   stress        - Processed raw stress vector.
%   strain_smooth - Smoothed strain vector.
%   stress_smooth - Smoothed stress vector.
%   E_t           - Tangent modulus used for analysis.
%   E_t_plot      - Smoothed tangent modulus used for plotting.
%   E_median      - Median modulus within the modulus window.

    deformation = deformation(:);
    force = force(:);

    valid = ~isnan(deformation) & ~isnan(force);
    deformation = deformation(valid);
    force = force(valid);

    if settings.zero_displacement_at_start
        deformation = deformation - deformation(1);
    end

    if settings.zero_force_at_start
        force = force - force(1);
    end

    strain = deformation / geometry.h0;
    stress = force / geometry.area;

    valid = strain >= 0;
    strain = strain(valid);
    stress = stress(valid);

    [idx_start, idx_end] = getCompressionWindow( ...
        strain, settings.window_mode, settings.manual_start_idx, settings.manual_end_idx);

    strain = strain(idx_start:idx_end);
    stress = stress(idx_start:idx_end);

    [strain, stress] = finalizeSelectedBranch(strain, stress, settings);

    [E_t, E_t_plot, E_median, strain_smooth, stress_smooth] = ...
        calculateTangentialModulus(strain, stress, settings);
end

function [idx_start, idx_end] = getCompressionWindow(strain, mode, manual_start_idx, manual_end_idx)
% Selects the compression loading branch of interest.
% Uses either manual indices or automatic detection of the last loading branch.
%
% Inputs:
%   strain           - Strain vector.
%   mode             - "auto" or "manual".
%   manual_start_idx - Manual start index.
%   manual_end_idx   - Manual end index.
%
% Outputs:
%   idx_start - Start index of selected branch.
%   idx_end   - End index of selected branch.

    n = length(strain);

    if mode == "manual"
        idx_start = max(1, manual_start_idx);
        idx_end = min(n, manual_end_idx);

        if idx_end <= idx_start
            error("manual_end_idx must be larger than manual_start_idx.");
        end

        return;
    end

    strain_smooth = smoothdata(strain, 'movmean', 25);
    dstrain = gradient(strain_smooth);

    threshold = 0.05 * max(abs(dstrain));

    if threshold == 0 || isnan(threshold)
        warning("Automatic window detection failed. Using full curve.");
        idx_start = 1;
        idx_end = n;
        return;
    end

    is_loading = dstrain > threshold;

    changes = diff([false; is_loading(:); false]);
    starts = find(changes == 1);
    ends = find(changes == -1) - 1;

    min_region_length = round(0.05 * n);
    valid_regions = (ends - starts + 1) > min_region_length;

    starts = starts(valid_regions);
    ends = ends(valid_regions);

    if isempty(starts)
        warning("Automatic window detection failed. Using full curve.");
        idx_start = 1;
        idx_end = n;
        return;
    end

    idx_start = starts(end);
    idx_end = ends(end);

    [~, local_max_idx] = max(strain_smooth(idx_start:end));
    idx_end = idx_start + local_max_idx - 1;

    if idx_end <= idx_start
        warning("Invalid automatic window. Using full curve.");
        idx_start = 1;
        idx_end = n;
    end
end

function template = conditionTemplate()
% Creates an empty condition structure.
%
% Inputs:
%   None.
%
% Outputs:
%   template - Empty condition structure.

    template = struct( ...
        'name', [], ...
        'file', [], ...
        'specimen_names', [], ...
        'specimens', [], ...
        'common_strain', [], ...
        'interp_stress', [], ...
        'interp_E_t', [], ...
        'interp_E_t_plot', [], ...
        'median_stress', [], ...
        'lower_stress_CI', [], ...
        'upper_stress_CI', [], ...
        'median_E_t', [], ...
        'lower_E_t_CI', [], ...
        'upper_E_t_CI', [], ...
        'median_E_t_plot', [], ...
        'lower_E_t_plot_CI', [], ...
        'upper_E_t_plot_CI', [], ...
        'E_all', [], ...
        'E_median', [], ...
        'E_lower_CI', [], ...
        'E_upper_CI', []);
end

function template = specimenTemplate()
% Creates an empty specimen structure.
%
% Inputs:
%   None.
%
% Outputs:
%   template - Empty specimen structure.

    template = struct( ...
        'sheetName', [], ...
        'label', [], ...
        'geometry', [], ...
        'strain', [], ...
        'stress', [], ...
        'strain_smooth', [], ...
        'stress_smooth', [], ...
        'E_t', [], ...
        'E_t_plot', [], ...
        'E_median', []);
end