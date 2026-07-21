function result = analyzeGroupComparison(analysis,groupNames,config)
%ANALYZEGROUPCOMPARISON Build group populations and pairwise comparisons.
arguments
    analysis (1,1) struct
    groupNames string = strings(0,1)
    config (1,1) struct = mechanics.config.groupComparisonConfig()
end
if ~isfield(analysis,"summary") || ...
   ~ismember(config.groupVariableName,string(analysis.summary.Properties.VariableNames))
    error("mechanics:workflow:MissingGroupAssignments", ...
        "Assign specimen groups before comparison.");
end
gv=string(analysis.summary.(config.groupVariableName));
processed=analysis.summary.Status=="processed";
if isempty(groupNames), groupNames=unique(gv(processed & gv~=""),"stable");
else, groupNames=string(groupNames(:)); end
if numel(groupNames)<2
    error("mechanics:workflow:InsufficientGroups", ...
        "At least two groups are required.");
end
groups=repmat(struct('name',"",'population',struct(),'specimenCount',0),numel(groupNames),1);
for g=1:numel(groupNames)
    name=groupNames(g); mask=false(numel(analysis.records),1);
    for k=1:numel(analysis.records)
        mask(k)=isfield(analysis.records(k),"group") && ...
            analysis.records(k).status=="processed" && ...
            string(analysis.records(k).group)==name;
    end
    rec=analysis.records(mask);
    if numel(rec)<config.minimumSpecimensPerGroup
        error("mechanics:workflow:InsufficientGroupSpecimens", ...
            "Group %s requires at least %d processed specimens.", ...
            name,config.minimumSpecimensPerGroup);
    end
    ga.records=rec;
    ga.summary=analysis.summary(processed & gv==name,:);
    pc=config.populationConfig; pc.minimumSpecimens=config.minimumSpecimensPerGroup;
    pop=mechanics.workflow.analyzeSpecimenPopulation(ga,pc);
    groups(g).name=name; groups(g).population=pop; groups(g).specimenCount=pop.specimenCount;
end
result.groups=groups; result.groupNames=groupNames; result.config=config; result.createdAt=datetime("now");
if numel(groupNames)==2
    A=groups(1).population; A.name=groups(1).name;
    B=groups(2).population; B.name=groups(2).name;
    result.curveComparison=mechanics.statistics.compareGroupCurves(A,B,config);
    S=analysis.summary; S.Group=string(S.(config.groupVariableName));
    result.metricComparison=mechanics.statistics.compareGroupMetrics(S,groupNames(1),groupNames(2),config);
else
    result.curveComparison=struct(); result.metricComparison=table();
end
if config.export.enabled
    result.outputFiles=mechanics.io.exportGroupComparison(result,config.export.outputFolder);
end
end
