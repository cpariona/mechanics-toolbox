function units = resolveStudyUnits(records)
%RESOLVESTUDYUNITS Resolve stored units from processed study records.
arguments
    records struct
end

units.force = "N";
units.displacement = "mm";
units.strain = "-";
units.stress = "MPa";
units.energy = "mJ";

if isempty(records)
    return;
end

status = string({records.status});
index = find(status == "processed", 1, "first");
if isempty(index) || ~isfield(records(index), "specimen")
    return;
end

specimen = records(index).specimen;
if ~isfield(specimen, "processed") || ...
        ~isfield(specimen.processed, "units")
    return;
end

source = specimen.processed.units;
names = fieldnames(source);
for k = 1:numel(names)
    units.(names{k}) = string(source.(names{k}));
end

if units.strain == "1" || strlength(units.strain) == 0
    units.strain = "-";
end
end