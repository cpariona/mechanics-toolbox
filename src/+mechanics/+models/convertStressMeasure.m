function stress = convertStressMeasure(nominalStress, lambda, context)
%CONVERTSTRESSMEASURE Convert nominal stress to the requested measure.
arguments
    nominalStress {mustBeNumeric, mustBeReal}
    lambda {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

outputMeasure = "nominal";
if isfield(context, "outputStressMeasure")
    outputMeasure = lower(string(context.outputStressMeasure));
end

switch outputMeasure
    case {"nominal", "engineering", "first-piola"}
        stress = nominalStress;
    case {"cauchy", "true"}
        stress = lambda .* nominalStress;
    otherwise
        error("mechanics:models:UnknownStressMeasure", ...
            "Unknown output stress measure: %s", outputMeasure);
end
end
