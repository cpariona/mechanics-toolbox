function stress = neoHookean(deformation, parameters, context)
%NEOHOOKEAN Evaluate incompressible Neo-Hookean uniaxial stress.
arguments
    deformation {mustBeNumeric, mustBeReal}
    parameters {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

mechanics.models.validateParameters(parameters, 1, "neo-hookean");
mu = parameters(1);
lambda = mechanics.models.toStretch(deformation, context);
nominalStress = mu .* (lambda - lambda.^(-2));
stress = mechanics.models.convertStressMeasure(nominalStress, lambda, context);
end
