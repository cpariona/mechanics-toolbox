function stress = convertStressMeasure(nominalStress, lambda, context)
%CONVERTSTRESSMEASURE Convert nominal stress to the requested measure.
arguments
    nominalStress {mustBeNumeric, mustBeReal}
    lambda {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

stressMeasure = "nominal";
if isfield(context, "stressMeasure")
    stressMeasure = lower(string(context.stressMeasure));
end

switch stressMeasure
    case {"nominal", "engineering", "first-piola"}
        stress = nominalStress;
    case {"cauchy", "true"}
        stress = lambda .* nominalStress;
    otherwise
        error("mechanics:models:UnknownStressMeasure", ...
            "Unknown stress measure: %s", stressMeasure);
end
end
