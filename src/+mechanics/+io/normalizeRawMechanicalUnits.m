function [force, displacement, units, conversion] = ...
        normalizeRawMechanicalUnits(force, displacement, units)
%NORMALIZERAWMECHANICALUNITS Convert supported raw units to N and mm.
arguments
    force {mustBeNumeric, mustBeReal}
    displacement {mustBeNumeric, mustBeReal}
    units (1,1) struct
end

if ~isfield(units, "force") || strlength(string(units.force)) == 0
    units.force = "N";
end
if ~isfield(units, "displacement") || ...
        strlength(string(units.displacement)) == 0
    units.displacement = "mm";
end

[forceScale, normalizedForceUnit] = localForceScale(units.force);
[displacementScale, normalizedDisplacementUnit] = ...
    localDisplacementScale(units.displacement);

force = force .* forceScale;
displacement = displacement .* displacementScale;
conversion.originalForceUnit = string(units.force);
conversion.originalDisplacementUnit = string(units.displacement);
conversion.forceScale = forceScale;
conversion.displacementScale = displacementScale;
conversion.forceUnit = normalizedForceUnit;
conversion.displacementUnit = normalizedDisplacementUnit;

units.force = normalizedForceUnit;
units.displacement = normalizedDisplacementUnit;
units.stress = "MPa";
units.strain = "-";
units.energy = "mJ";
end

function [scale, unit] = localForceScale(value)
normalized = lower(strtrim(string(value)));
normalized = replace(normalized, " ", "");
switch normalized
    case {"n", "newton", "newtons"}
        scale = 1;
    case {"mn", "millinewton", "millinewtons"}
        scale = 1e-3;
    case {"kn", "kilonewton", "kilonewtons"}
        scale = 1e3;
    otherwise
        error("mechanics:io:UnsupportedForceUnit", ...
            "Unsupported force unit: %s", string(value));
end
unit = "N";
end

function [scale, unit] = localDisplacementScale(value)
normalized = lower(strtrim(string(value)));
normalized = replace(normalized, [" ", "µ"], ["", "u"]);
switch normalized
    case {"mm", "millimeter", "millimeters", ...
            "millimetre", "millimetres"}
        scale = 1;
    case {"um", "micrometer", "micrometers", ...
            "micrometre", "micrometres"}
        scale = 1e-3;
    case {"cm", "centimeter", "centimeters", ...
            "centimetre", "centimetres"}
        scale = 10;
    case {"m", "meter", "meters", "metre", "metres"}
        scale = 1e3;
    otherwise
        error("mechanics:io:UnsupportedDisplacementUnit", ...
            "Unsupported displacement unit: %s", string(value));
end
unit = "mm";
end