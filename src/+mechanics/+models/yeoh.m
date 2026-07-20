function stress = yeoh(deformation, parameters, context)
%YEOH Evaluate incompressible third-order Yeoh uniaxial stress.
arguments
    deformation {mustBeNumeric, mustBeReal}
    parameters {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

mechanics.models.validateParameters(parameters, 3, "yeoh");
C10 = parameters(1);
C20 = parameters(2);
C30 = parameters(3);
lambda = mechanics.models.toStretch(deformation, context);
I1minus3 = lambda.^2 + 2 .* lambda.^(-1) - 3;
dWdI1 = C10 + 2 .* C20 .* I1minus3 + 3 .* C30 .* I1minus3.^2;
nominalStress = 2 .* dWdI1 .* (lambda - lambda.^(-2));
stress = mechanics.models.convertStressMeasure(nominalStress, lambda, context);
end
