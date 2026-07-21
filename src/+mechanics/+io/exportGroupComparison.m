function outputFiles = exportGroupComparison(result,outputFolder)
%EXPORTGROUPCOMPARISON Export grouped populations and comparisons.
if ~isfolder(outputFolder), mkdir(outputFolder); end
name=strings(numel(result.groups),1); count=zeros(numel(result.groups),1);
for k=1:numel(result.groups)
    name(k)=result.groups(k).name; count(k)=result.groups(k).specimenCount;
    folder=fullfile(outputFolder,regexprep(name(k),"[^A-Za-z0-9_-]","_"));
    mechanics.io.exportPopulationAnalysis(result.groups(k).population,folder);
end
summary=table(name,count,'VariableNames',{'Group','SpecimenCount'});
summaryFile=fullfile(outputFolder,"group_summary.csv"); writetable(summary,summaryFile);
outputFiles.groupSummary=string(summaryFile);
if isfield(result,"curveComparison") && ~isempty(fieldnames(result.curveComparison))
    c=result.curveComparison;
    T=table(c.strain,c.meanStressA,c.meanStressB,c.meanDifference,c.confidenceLower,c.confidenceUpper, ...
      'VariableNames',{'Strain','MeanStressA','MeanStressB','MeanDifference','ConfidenceLower','ConfidenceUpper'});
    curveFile=fullfile(outputFolder,"pairwise_curve_comparison.csv");
    metricFile=fullfile(outputFolder,"pairwise_metric_comparison.csv");
    writetable(T,curveFile); writetable(result.metricComparison,metricFile);
    outputFiles.curveComparison=string(curveFile); outputFiles.metricComparison=string(metricFile);
end
matFile=fullfile(outputFolder,"group_comparison.mat"); save(matFile,"result");
outputFiles.comparison=string(matFile);
end
