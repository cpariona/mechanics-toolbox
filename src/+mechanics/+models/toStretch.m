function lambda = toStretch(deformation, context)
%TOSTRETCH Convert the selected deformation measure to stretch.
arguments
    deformation {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

deformationMeasure = "engineering-strain";
if isfield(context, "deformationMeasure")
    deformationMeasure = lower(string(context.deformationMeasure));
end

switch deformationMeasure
    case {"engineering-strain", "engineering", "strain"}
        lambda = 1 + deformation;
    case {"true-strain", "log-strain", "logarithmic-strain"}
        lambda = exp(deformation);
    case "stretch"
        lambda = deformation;
    otherwise
        error("mechanics:models:UnknownDeformationMeasure", ...
            "Unknown deformation measure: %s", deformationMeasure);
end

if any(~isfinite(lambda(:))) || any(lambda(:) <= 0)
    error("mechanics:models:InvalidStretch", ...
        "All stretch values must be positive and finite.");
end
end
