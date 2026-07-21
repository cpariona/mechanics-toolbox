%RUN_GROUP_COMPARISON Compare two experimental conditions.
startup;
assignments=table(["ECOFLEX0050-1";"ECOFLEX0050-2";"ECOFLEX0050-3";"ECOFLEX0050-4"], ...
 ["control";"control";"treated";"treated"], ...
 'VariableNames',{'SpecimenId','Group'});
groupedAnalysis=mechanics.workflow.assignSpecimenGroups(analysis,assignments);
config=mechanics.config.groupComparisonConfig();
comparison=mechanics.workflow.analyzeGroupComparison(groupedAnalysis,["control","treated"],config);
disp(comparison.metricComparison);
mechanics.plotting.plotGroupComparison(comparison);
files=mechanics.io.exportGroupComparison(comparison,"results/group-comparison");
disp(files);
