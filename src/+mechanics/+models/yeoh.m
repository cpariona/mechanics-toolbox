function stress = yeoh(deformation, parameters, context)
%YEOH Evaluate incompressible second- or third-order Yeoh uniaxial stress.
arguments
    deformation {mustBeNumeric, mustBeReal}
    parameters {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

parameterCount = numel(parameters);
if parameterCount ~= 2 && parameterCount ~= 3
    error("mechanics:models:InvalidParameterCount", ...
        "Yeoh requires 2 or 3 parameters.");
end
mechanics.models.validateParameters(parameters, parameterCount, "yeoh");

C10 = parameters(1);
C20 = parameters(2);
lambda = mechanics.models.toStretch(deformation, context);
I1minus3 = lambda.^2 + 2 .* lambda.^(-1) - 3;
dWdI1 = C10 + 2 .* C20 .* I1minus3;

if parameterCount == 3
    C30 = parameters(3);
    dWdI1 = dWdI1 + 3 .* C30 .* I1minus3.^2;
end

nominalStress = 2 .* dWdI1 .* (lambda - lambda.^(-2));
stress = mechanics.models.convertStressMeasure(nominalStress, lambda, context);
end
