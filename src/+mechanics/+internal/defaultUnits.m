function units = defaultUnits(rawCurve)
%DEFAULTUNITS Return explicit units, preserving supplied metadata.
units.force = "N";
units.displacement = "mm";
units.stress = "MPa";
units.strain = "1";
if isfield(rawCurve, "units")
    names = fieldnames(rawCurve.units);
    for index = 1:numel(names)
        units.(names{index}) = string(rawCurve.units.(names{index}));
    end
end
end
