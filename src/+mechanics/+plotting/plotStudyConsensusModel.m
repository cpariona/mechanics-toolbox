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
modelLabels = categorical(summary.ModelName, summary.ModelName);

axesBic = nexttile(layout);
barHandle = bar(axesBic, modelLabels, summary.DeltaBIC);
barHandle.FaceColor = 'flat';
if consensus.hasConsensusModel
    selectedMask = summary.ModelName == consensus.modelName;
    barHandle.CData = repmat([0.35 0.35 0.35], height(summary), 1);
    barHandle.CData(selectedMask,:) = [0.15 0.55 0.20];
end
for index = 1:height(summary)
    if isfinite(summary.DeltaBIC(index))
        text(axesBic, index, summary.DeltaBIC(index), ...
            sprintf('  %.3g', summary.DeltaBIC(index)), ...
            'HorizontalAlignment','left', ...
            'VerticalAlignment','middle', ...
            'Rotation',90);
    end
end
ylabel(axesBic,'\DeltaBIC from best accepted model');
title(axesBic,'Model evidence');
xtickangle(axesBic,25);
grid(axesBic,'on');
box(axesBic,'on');

axesEligibility = nexttile(layout);
hold(axesEligibility,'on');
bar(axesEligibility, modelLabels, summary.EligibleFitFraction, ...
    'DisplayName','Eligible fit fraction');
yline(axesEligibility, consensus.config.minimumEligibleFraction, '--', ...
    'Minimum eligible fraction', ...
    'LabelHorizontalAlignment','right', ...
    'LabelVerticalAlignment','bottom', ...
    'HandleVisibility','off');
ylabel(axesEligibility,'Eligible fit fraction');
ylim(axesEligibility,[0 1.05]);
title(axesEligibility,'Cross-specimen eligibility');
xtickangle(axesEligibility,25);
grid(axesEligibility,'on');
box(axesEligibility,'on');

if consensus.hasConsensusModel
    sgtitle(figureHandle, ...
        'Consensus model: ' + consensus.modelName, 'Interpreter','none');
else
    sgtitle(figureHandle,'No study consensus model','Interpreter','none');
end
end
