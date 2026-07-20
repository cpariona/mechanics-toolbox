function experiment = processTensionExperiment(files, ratios, specimens_list, settings)
% Processes tension experiments from raw Excel files.
% Computes stress, strain, tangent modulus, median curves, and bootstrap
% confidence intervals.
%
% Inputs:
%   files          - Cell array with full Excel file paths.
%   ratios         - Cell array with material or condition names.
%   specimens_list - Cell array with specimen sheet names per file.
%   settings       - Structure with processing and bootstrap settings.
%
% Outputs:
%   experiment - Structure containing processed tension data.

    experiment.testType = 'Tension';
    experiment.files = files;
    experiment.ratios = ratios;
    experiment.settings = settings;
    experiment.labels = getTensionLabels();

    conditions = repmat(conditionTemplate(), 1, numel(files));

    for f = 1:numel(files)

        data = readMechanicalExcelFile(files{f});
        resultsTbl = data{2,2};
        statsTbl = data{3,2};
        specimens = specimens_list{f};

        calibratedLength = getTensionCalibratedLength(statsTbl, settings);

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

            geometry = getTensionGeometry(resultsTbl, sheetName, calibratedLength);
            specimenTbl = getSheetTable(data, sheetName);

            elongation = getTableColumn(specimenTbl, {'Elongation','Deformación','Deformacion'});
            force      = getTableColumn(specimenTbl, {'Standard force','Fuerza estándar','Fuerza estandar'});

            [strain, stress, strain_smooth, stress_smooth, E_t, E_t_plot, E_median] = ...
                processTensionSpecimen(elongation, force, geometry, settings);

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

function labels = getTensionLabels()
% Defines labels used in tension plots.
%
% Inputs:
%   None.
%
% Outputs:
%   labels - Structure with plot labels.

    labels.testName = 'Tension';
    labels.strain = 'Tensile strain [mm/mm]';
    labels.stress = 'Tensile stress [MPa]';
    labels.modulus = 'Tangential Young''s modulus [MPa]';
    labels.modulusSymbol = 'E';
end

function geometry = getTensionGeometry(resultsTbl, sheetName, calibratedLength)
% Gets tension specimen geometry from the results table.
%
% Inputs:
%   resultsTbl        - Results table from the Excel file.
%   sheetName         - Specimen sheet name.
%   calibratedLength  - Gauge length used for strain calculation.
%
% Outputs:
%   geometry - Structure with h, b, area, and calibrated length.

    geometry.h = getResultValue(resultsTbl, sheetName, 'h');
    geometry.b = getResultValue(resultsTbl, sheetName, 'b');
    geometry.area = geometry.h * geometry.b;
    geometry.calibrated_length = calibratedLength;
end

function calibratedLength = getTensionCalibratedLength(statsTbl, settings)
% Gets or estimates the calibrated length for tension tests.
% If settings.calibrated_length is defined, it is used directly.
%
% Inputs:
%   statsTbl - Statistics table from the Excel file.
%   settings - Structure with tension settings.
%
% Outputs:
%   calibratedLength - Gauge length in mm.

    if isfield(settings, 'calibrated_length') && ...
            ~isempty(settings.calibrated_length) && ...
            ~isnan(settings.calibrated_length)

        calibratedLength = settings.calibrated_length;
        return;
    end

    eB = getTableColumn(statsTbl, {'eB'});
    eB_percent = getTableColumn(statsTbl, {'eB 2','eB2'});

    valid = ~isnan(eB) & ~isnan(eB_percent) & eB_percent ~= 0;

    if ~any(valid)
        error("Could not estimate calibrated length from Statistics sheet.");
    end

    idx = find(valid, 1, 'first');
    calibratedLength = eB(idx) / (eB_percent(idx) / 100);
end

function [strain, stress, strain_smooth, stress_smooth, E_t, E_t_plot, E_median] = processTensionSpecimen(elongation, force, geometry, settings)
% Processes one tension specimen.
% Converts raw data into stress, strain, and tangent modulus.
%
% Inputs:
%   elongation - Raw elongation vector.
%   force      - Raw force vector.
%   geometry   - Structure with specimen geometry.
%   settings   - Structure with processing settings.
%
% Outputs:
%   strain        - Processed raw strain vector.
%   stress        - Processed raw stress vector.
%   strain_smooth - Smoothed strain vector.
%   stress_smooth - Smoothed stress vector.
%   E_t           - Tangent modulus used for analysis.
%   E_t_plot      - Smoothed tangent modulus used for plotting.
%   E_median      - Median modulus within the modulus window.

    elongation = elongation(:);
    force = force(:);

    valid = ~isnan(elongation) & ~isnan(force);
    elongation = elongation(valid);
    force = force(valid);

    if settings.zero_displacement_at_start
        elongation = elongation - elongation(1);
    end

    if settings.zero_force_at_start
        force = force - force(1);
    end

    strain = elongation / geometry.calibrated_length;
    stress = force / geometry.area;

    valid = strain >= 0;
    strain = strain(valid);
    stress = stress(valid);

    [idx_start, idx_end] = getTensionWindow( ...
        strain, settings.window_mode, settings.manual_start_idx, settings.manual_end_idx);

    strain = strain(idx_start:idx_end);
    stress = stress(idx_start:idx_end);

    [strain, stress] = finalizeSelectedBranch(strain, stress, settings);

    [E_t, E_t_plot, E_median, strain_smooth, stress_smooth] = ...
        calculateTangentialModulus(strain, stress, settings);
end

function [idx_start, idx_end] = getTensionWindow(strain, mode, manual_start_idx, manual_end_idx)
% Selects the tension curve window.
% Uses the full curve by default or manual indices if requested.
%
% Inputs:
%   strain           - Strain vector.
%   mode             - "full" or "manual".
%   manual_start_idx - Manual start index.
%   manual_end_idx   - Manual end index.
%
% Outputs:
%   idx_start - Start index of selected window.
%   idx_end   - End index of selected window.

    n = length(strain);

    if mode == "manual"
        idx_start = max(1, manual_start_idx);
        idx_end = min(n, manual_end_idx);

        if idx_end <= idx_start
            error("manual_end_idx must be larger than manual_start_idx.");
        end
    else
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