clear
clc
close all
startup

rng(4)
strain = linspace(0, 1, 151)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
stress = mechanics.models.evaluateModel("yeoh", strain, [0.08, 0.02, 0.003], context);
stress = stress + 0.001 * randn(size(stress));

config = mechanics.config.fittingConfig();
config.numberOfStarts = 10;
comparison = mechanics.fitting.fitMultipleModels( ...
    ["neo-hookean", "mooney-rivlin", "yeoh"], ...
    strain, stress, context, config);

disp(comparison.summary)
fprintf('Best model by BIC: %s\n', comparison.bestModelByBIC)
