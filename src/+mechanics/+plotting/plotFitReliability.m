function figureHandle = plotFitReliability(assessment)
%PLOTFITRELIABILITY Plot available and flagged reliability components.
arguments
    assessment (1,1) struct
end

summary = assessment.componentSummary;
values = double(summary.Flagged);
values(~summary.Available) = NaN;

figureHandle = figure("Color", "w");
bar(categorical(summary.Component), values);
ylim([0, 1.2]);
yticks([0, 1]);
yticklabels({'Pass', 'Flag'});
ylabel("Diagnostic status");
title(sprintf("%s fit reliability: %s", ...
    strrep(char(assessment.modelName), "-", " "), ...
    char(assessment.status)));
grid on;
box on;
end