function analysis = addPeakMetrics(analysis, config)
%ADDPEAKMETRICS Compute peak metrics for processed specimens.
arguments
    analysis (1,1) struct
    config (1,1) struct = mechanics.config.peakAnalysisConfig()
end

analysis.peakAnalysisConfig = config;
if ~config.enabled
    analysis.peakSummary = table();
    return;
end

for index = 1:numel(analysis.records)
    if analysis.records(index).status ~= "processed"
        continue;
    end
    specimen = analysis.records(index).specimen;
    specimen.peakMetrics = mechanics.analysis.computePeakMetrics(specimen, config);
    analysis.records(index).specimen = specimen;
end

analysis.peakSummary = mechanics.workflow.summarizePeakMetrics(analysis.records);
end
