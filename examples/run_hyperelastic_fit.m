clear
clc
close all
startup

rng(3)
strain = linspace(0, 1, 151)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
trueParameters = [0.08, 0.025];
cleanStress = mechanics.models.evaluateModel( ...
    "mooney-rivlin", strain, trueParameters, context);
measuredStress = cleanStress + 0.001 * randn(size(cleanStress));

config = mechanics.config.fittingConfig();
config.numberOfStarts = 12;
fitResult = mechanics.fitting.fitModel( ...
    "mooney-rivlin", strain, measuredStress, context, config);

disp(table(fitResult.parameterNames(:), fitResult.parameters(:), ...
    'VariableNames', {'Parameter','EstimatedValue'}))
disp(struct2table(fitResult.metrics))
mechanics.plotting.plotModelFit(fitResult);
