function figureHandle = plotStudyConsensusModel(consensus)
%PLOTSTUDYCONSENSUSMODEL Plot study-level model evidence.
arguments
    consensus (1,1) struct
end

figureHandle = figure('Color','w');
summary = consensus.metricSummary;
if isempty(summary)
    axesHandle = axes(figureHandle); %#ok<LAXES>
    text(axesHandle,0.5,0.5,'No consensus-model evidence', ...
        'HorizontalAlignment','center');
    axis(axesHandle,'off');
    return;
end

layout = tiledlayout(figureHandle,1,2, ...
    'TileSpacing','compact','Padding','compact');

axesBic = nexttile(layout);
bar(axesBic, categorical(summary.ModelName), summary.MedianBIC);
ylabel(axesBic,'Median BIC');
title(axesBic,'Model evidence');
grid(axesBic,'on');
box(axesBic,'on');

axesEligibility = nexttile(layout);
hold(axesEligibility,'on');
bar(axesEligibility, categorical(summary.ModelName), ...
    summary.EligibleFitFraction, 'DisplayName','Eligible');
yline(axesEligibility, consensus.config.minimumEligibleFraction, '--', ...
    'Minimum eligible fraction', 'DisplayName','Threshold');
ylabel(axesEligibility,'Eligible fit fraction');
ylim(axesEligibility,[0 1]);
title(axesEligibility,'Cross-specimen eligibility');
grid(axesEligibility,'on');
box(axesEligibility,'on');

if consensus.hasConsensusModel
    sgtitle(figureHandle, ...
        'Consensus model: ' + consensus.modelName, 'Interpreter','none');
else
    sgtitle(figureHandle,'No study consensus model','Interpreter','none');
end
end
