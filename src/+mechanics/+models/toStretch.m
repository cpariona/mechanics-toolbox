function lambda = toStretch(deformation, context)
%TOSTRETCH Convert the selected deformation measure to stretch.
arguments
    deformation {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

inputMeasure = "engineering-strain";
if isfield(context, "inputMeasure")
    inputMeasure = lower(string(context.inputMeasure));
end

switch inputMeasure
    case {"engineering-strain", "engineering", "strain"}
        lambda = 1 + deformation;
    case {"true-strain", "log-strain", "logarithmic-strain"}
        lambda = exp(deformation);
    case "stretch"
        lambda = deformation;
    otherwise
        error("mechanics:models:UnknownInputMeasure", ...
            "Unknown deformation input measure: %s", inputMeasure);
end

if any(~isfinite(lambda(:))) || any(lambda(:) <= 0)
    error("mechanics:models:InvalidStretch", ...
        "All stretch values must be positive and finite.");
end
end
