%RUN_HYPERELASTIC_MODELS Compare registered models on a common strain range.
startup;

engineeringStrain = linspace(0, 1, 301)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

neoHookeanStress = mechanics.models.evaluateModel( ...
    "neo-hookean", engineeringStrain, 0.10, context);
mooneyRivlinStress = mechanics.models.evaluateModel( ...
    "mooney-rivlin", engineeringStrain, [0.04, 0.01], context);
yeohStress = mechanics.models.evaluateModel( ...
    "yeoh", engineeringStrain, [0.05, 0.01, 0.002], context);

figure("Color", "w");
plot(engineeringStrain, neoHookeanStress, "LineWidth", 1.5);
hold on;
plot(engineeringStrain, mooneyRivlinStress, "LineWidth", 1.5);
plot(engineeringStrain, yeohStress, "LineWidth", 1.5);
xlabel("Engineering strain");
ylabel("Nominal stress");
legend("Neo-Hookean", "Mooney-Rivlin", "Yeoh", "Location", "best");
grid on;
box on;
