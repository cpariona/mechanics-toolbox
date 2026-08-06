function label = mechanicalAxisLabel(quantity, measure, unit)
%MECHANICALAXISLABEL Build concise mechanical axis labels with units.
arguments
    quantity (1,1) string
    measure (1,1) string = ""
    unit (1,1) string = ""
end
quantity = lower(strtrim(quantity));
measure = lower(strtrim(measure));

switch quantity
    case "deformation"
        displayUnit = mechanics.plotting.mechanicalDisplayUnit( ...
            "deformation", unit);
        switch measure
            case "engineering-strain"
                base = "Engineering strain";
            case "true-strain"
                base = "True strain";
            otherwise
                base = "Deformation";
        end
    case "stress"
        displayUnit = mechanics.plotting.mechanicalDisplayUnit("stress", unit);
        switch measure
            case "nominal"
                base = "Nominal stress";
            case "cauchy"
                base = "Cauchy stress";
            otherwise
                base = "Stress";
        end
    case "residual"
        displayUnit = mechanics.plotting.mechanicalDisplayUnit("stress", unit);
        base = "Residual";
    case "compression-magnitude-residual"
        displayUnit = mechanics.plotting.mechanicalDisplayUnit("stress", unit);
        base = "Magnitude residual";
    case "objective"
        displayUnit = mechanics.plotting.mechanicalDisplayUnit("objective", unit);
        base = "Objective";
    otherwise
        error("mechanics:plotting:UnknownMechanicalAxisQuantity", ...
            "Unsupported mechanical axis quantity: %s.", quantity);
end

label = mechanics.plotting.formatUnitLabel(base, displayUnit);
end
