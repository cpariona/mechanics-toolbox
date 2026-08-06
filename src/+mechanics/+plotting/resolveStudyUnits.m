function units = resolveStudyUnits(records)
%RESOLVESTUDYUNITS Resolve display units from processed study records.
arguments
    records struct
end

units.force = "N";
units.displacement = "mm";
units.strain = "-";
units.stress = "MPa";
units.energy = "mJ";

if ~isempty(records)
    status = string({records.status});
    index = find(status == "processed", 1, "first");
    if ~isempty(index) && isfield(records(index), "specimen")
        specimen = records(index).specimen;
        if isfield(specimen, "processed") && ...
                isfield(specimen.processed, "units")
            source = specimen.processed.units;
            names = fieldnames(source);
            for k = 1:numel(names)
                units.(names{k}) = string(source.(names{k}));
            end
        end
    end
end

units.strain = mechanics.plotting.mechanicalDisplayUnit( ...
    "deformation", units.strain);
units.stress = mechanics.plotting.mechanicalDisplayUnit( ...
    "stress", units.stress);
end
