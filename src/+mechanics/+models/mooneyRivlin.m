function stress = mooneyRivlin(deformation, parameters, context)
%MOONEYRIVLIN Evaluate incompressible Mooney-Rivlin uniaxial stress.
arguments
    deformation {mustBeNumeric, mustBeReal}
    parameters {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

mechanics.models.validateParameters(parameters, 2, "mooney-rivlin");
C10 = parameters(1);
C01 = parameters(2);
lambda = mechanics.models.toStretch(deformation, context);
nominalStress = 2 .* C10 .* (lambda - lambda.^(-2)) ...
    + 2 .* C01 .* (1 - lambda.^(-3));
stress = mechanics.models.convertStressMeasure(nominalStress, lambda, context);
end
