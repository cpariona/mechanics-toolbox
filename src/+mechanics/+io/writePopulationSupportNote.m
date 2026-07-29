function writePopulationSupportNote(fileId, study)
%WRITEPOPULATIONSUPPORTNOTE Report pointwise tangent-modulus specimen support.
arguments
    fileId (1,1) double
    study (1,1) struct
end

if ~isfield(study, "population") || ...
        ~isfield(study.population, "tangentModulus") || ...
        ~isfield(study.population.tangentModulus, "specimenCountByPoint")
    return;
end
count = study.population.tangentModulus.specimenCountByPoint(:);
count = count(isfinite(count));
if isempty(count)
    return;
end
minimumCount = min(count);
maximumCount = max(count);
if minimumCount < maximumCount
    fprintf(fileId, [ ...
        "- Population tangent-modulus support varies from `n=%d` to `n=%d` " + ...
        "across the strain grid; support transitions are marked in the figure.\n"], ...
        minimumCount, maximumCount);
else
    fprintf(fileId, ...
        "- Population tangent-modulus support: `n=%d` across the strain grid.\n", ...
        maximumCount);
end
end