function label = mechanicalAxisLabel(quantity, measure, unit)
%MECHANICALAXISLABEL Build concise mechanical axis labels with units.
arguments
    quantity (1,1) string
    measure (1,1) string = ""
    unit (1,1) string = ""
end
quantity = lower(strtrim(quantity));
measure = lower(strtrim(measure));
if quantity == "deformation"
    displayUnit = mechanics.plotting.mechanicalDisplayUnit("deformation", unit);
elseif quantity == "objective"
    displayUnit = mechanics.plotting.mechanicalDisplayUnit("objective", unit);
else
    displayUnit = mechanics.plotting.mechanicalDisplayUnit("stress", unit);
end
switch quantity
    case "deformation"
        switch measure
            case "engineering-strain"
                base = "Engineering strain";
            case "true-strain"
                base = "True strain";
            otherwise
                base = "Deformation";
        end
    case "stress"
        switch measure
            case "nominal"
                base = "Nominal stress";
            case "cauchy"
                base = "Cauchy stress";
            otherwise
                base = "Stress";
        end
    case "residual"
        base = "Residual";
    case "compression-magnitude-residual"
        base = "Magnitude residual";
    case "objective"
        base = "Objective";
    otherwise
        error("mechanics:plotting:UnknownMechanicalAxisQuantity", ...
            "Unsupported mechanical axis quantity: %s.", quantity);
end
if strlength(displayUnit) > 0
    label = base + " [" + displayUnit + "]";
else
    label = base;
end
end
