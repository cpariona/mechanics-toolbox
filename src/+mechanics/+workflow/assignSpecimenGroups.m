function analysis = assignSpecimenGroups(analysis, assignments, groupVariableName)
%ASSIGNSPECIMENGROUPS Attach group labels using SpecimenId.
arguments
    analysis (1,1) struct
    assignments table
    groupVariableName (1,1) string = "Group"
end
required = ["SpecimenId", groupVariableName];
if ~all(ismember(required,string(assignments.Properties.VariableNames)))
    error("mechanics:workflow:InvalidGroupAssignments", ...
        "Assignments must contain SpecimenId and %s.",groupVariableName);
end
ids=string(assignments.SpecimenId);
groups=string(assignments.(groupVariableName));
if numel(unique(ids))~=numel(ids)
    error("mechanics:workflow:DuplicateGroupAssignment", ...
        "Each SpecimenId must appear only once.");
end
for k=1:numel(analysis.records)
    id=string(analysis.records(k).specimenId);
    j=find(ids==id,1);
    if isempty(j), analysis.records(k).group="";
    else, analysis.records(k).group=groups(j); end
end
if isfield(analysis,"summary") && istable(analysis.summary)
    out=strings(height(analysis.summary),1);
    for k=1:height(analysis.summary)
        j=find(ids==string(analysis.summary.SpecimenId(k)),1);
        if ~isempty(j), out(k)=groups(j); end
    end
    analysis.summary.(groupVariableName)=out;
end
end
