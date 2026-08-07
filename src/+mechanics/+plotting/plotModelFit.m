function fig = plotModelFit(fitResult)
%PLOTMODELFIT Plot measured stress and fitted model prediction.
arguments
    fitResult (1,1) struct
end
model = mechanics.models.modelRegistry(string(fitResult.modelName));
fig = figure('Color','w');
plot(fitResult.deformation, fitResult.measuredStress, 'o', ...
    'DisplayName','Experimental data');
hold on
plot(fitResult.deformation, fitResult.predictedStress, '-', ...
    'LineWidth',1.5, 'DisplayName',model.displayName);
grid on
xlabel('Deformation')
ylabel('Stress')
title(sprintf('%s fit, R^2 = %.5f', ...
    model.displayName, fitResult.metrics.rSquared))
legend('Location','best')
end
