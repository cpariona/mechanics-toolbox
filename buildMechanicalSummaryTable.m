function summaryTable = buildMechanicalSummaryTable(experiment)
% Builds a summary table for mechanical modulus results.
% Includes one row per experimental condition.
%
% Inputs:
%   experiment - Structure containing processed mechanical data.
%
% Outputs:
%   summaryTable - Table with condition-level modulus summaries.

    n = numel(experiment.conditions);

    testType = strings(n,1);
    material = strings(n,1);
    nSpecimens = zeros(n,1);
    E_median = zeros(n,1);
    E_lower_CI = zeros(n,1);
    E_upper_CI = zeros(n,1);

    for i = 1:n
        testType(i) = string(experiment.testType);
        material(i) = string(experiment.conditions(i).name);
        nSpecimens(i) = numel(experiment.conditions(i).specimens);
        E_median(i) = experiment.conditions(i).E_median;
        E_lower_CI(i) = experiment.conditions(i).E_lower_CI;
        E_upper_CI(i) = experiment.conditions(i).E_upper_CI;
    end

    summaryTable = table(testType, material, nSpecimens, ...
        E_median, E_lower_CI, E_upper_CI);
end