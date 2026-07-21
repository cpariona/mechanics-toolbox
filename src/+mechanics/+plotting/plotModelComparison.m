function figureHandle = plotModelComparison(comparison)
%PLOTMODELCOMPARISON Plot criterion values for eligible fitted models.
arguments
    comparison (1,1) struct
end

summary = comparison.summary;
values = summary.CriterionValue;
values(~summary.Eligible | ~summary.Success) = NaN;

figureHandle = figure("Color", "w");
bar(categorical(summary.ModelName), values);
ylabel(upper(char(comparison.selectionCriterion)));
title("Reliability-aware constitutive model comparison");
grid on;
box on;
end
