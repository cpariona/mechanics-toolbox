function unit = mechanicalDisplayUnit(quantity, unit)
%MECHANICALDISPLAYUNIT Normalize units for human-facing mechanical outputs.
arguments
    quantity (1,1) string
    unit (1,1) string = ""
end
quantity = lower(strtrim(quantity));
unit = strtrim(string(unit));
switch quantity
    case "deformation"
        if ismember(lower(unit), ["", "1", "-", "dimensionless"])
            unit = "mm/mm";
        end
    case "stress"
        % Stress units are already explicit and are preserved.
    otherwise
        error("mechanics:plotting:UnknownMechanicalDisplayQuantity", ...
            "Unsupported mechanical display quantity: %s.", quantity);
end
end
