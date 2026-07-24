function [area, unit, conversion] = normalizeAreaUnits(area, sourceUnit)
%NORMALIZEAREAUNITS Convert cross-sectional area values to square millimetres.
arguments
    area {mustBeNumeric, mustBeReal}
    sourceUnit = "mm2"
end

unitText = lower(strtrim(string(sourceUnit)));
unitText = replace(unitText, ["²", "^2", " ", "·"], ["2", "2", "", ""]);
unitText = replace(unitText, "μ", "u");
unitText = replace(unitText, "µ", "u");

switch unitText
    case {"", "mm2", "mm²", "squaremillimetre", "squaremillimeter", ...
            "squaremillimetres", "squaremillimeters"}
        factor = 1;
        canonicalSource = "mm2";
    case {"um2", "micrometre2", "micrometer2", ...
            "squaremicrometre", "squaremicrometer"}
        factor = 1e-6;
        canonicalSource = "um2";
    case {"cm2", "squarecentimetre", "squarecentimeter"}
        factor = 100;
        canonicalSource = "cm2";
    case {"m2", "squaremetre", "squaremeter"}
        factor = 1e6;
        canonicalSource = "m2";
    case {"in2", "inch2", "squareinch", "squareinches"}
        factor = 645.16;
        canonicalSource = "in2";
    otherwise
        error("mechanics:io:UnsupportedAreaUnit", ...
            "Unsupported cross-sectional area unit: %s", sourceUnit);
end

area = area(:) .* factor;
unit = "mm2";
conversion.sourceUnit = canonicalSource;
conversion.targetUnit = unit;
conversion.factor = factor;
end
