function label = mechanicalAxisLabel(quantity, measure, unit)
%MECHANICALAXISLABEL Build consistent mechanical axis labels with units.
arguments
    quantity (1,1) string
    measure (1,1) string = ""
    unit (1,1) string = ""
end
quantity = lower(strtrim(quantity));
measure = lower(strtrim(measure));
unit = localDisplayUnit(quantity, unit);
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
        switch measure
            case "nominal"
                base = "Nominal stress residual";
            case "cauchy"
                base = "Cauchy stress residual";
            otherwise
                base = "Stress residual";
        end
    case "compression-magnitude-residual"
        switch measure
            case "nominal"
                base = "Nominal compressive-stress magnitude residual";
            case "cauchy"
                base = "Cauchy compressive-stress magnitude residual";
            otherwise
                base = "Compressive-stress magnitude residual";
        end
    otherwise
        error("mechanics:plotting:UnknownMechanicalAxisQuantity", ...
            "Unsupported mechanical axis quantity: %s.", quantity);
end
if strlength(unit) > 0
    label = base + " [" + unit + "]";
else
    label = base;
end
end

function unit = localDisplayUnit(quantity, unit)
unit = strtrim(string(unit));
if quantity == "deformation" && ismember(lower(unit), ["", "1", "-", "dimensionless"])
    unit = "mm/mm";
end
end
