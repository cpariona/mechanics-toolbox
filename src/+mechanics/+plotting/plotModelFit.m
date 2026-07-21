function fig = plotModelFit(fitResult)
%PLOTMODELFIT Plot measured stress and fitted model prediction.
arguments
    fitResult (1,1) struct
end
fig = figure('Color','w');
plot(fitResult.deformation, fitResult.measuredStress, 'o', ...
    'DisplayName','Experimental data');
hold on
plot(fitResult.deformation, fitResult.predictedStress, '-', ...
    'LineWidth',1.5, 'DisplayName',fitResult.modelName);
grid on
xlabel('Deformation')
ylabel('Stress')
title(sprintf('%s fit, R^2 = %.5f', ...
    fitResult.modelName, fitResult.metrics.rSquared))
legend('Location','best')
end
