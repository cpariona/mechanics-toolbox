function analysis = addFractureMetrics(analysis, config)
%ADDFRACTUREMETRICS Compute fracture metrics for processed specimens.
arguments
    analysis (1,1) struct
    config (1,1) struct = mechanics.config.fractureAnalysisConfig()
end

analysis.fractureConfig = config;
if ~config.enabled
    analysis.fractureSummary = table();
    return;
end

for index = 1:numel(analysis.records)
    record = analysis.records(index);

    if record.status ~= "processed"
        continue;
    end

    specimen = record.specimen;

    specimen.fracture = ...
        mechanics.analysis.computeFractureMetrics( ...
            specimen, config);

    analysis.records(index).specimen = specimen;
end

analysis.fractureSummary = ...
    mechanics.workflow.summarizeFractureMetrics( ...
        analysis.records);
end
