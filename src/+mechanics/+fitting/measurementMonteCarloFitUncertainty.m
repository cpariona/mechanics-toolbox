function uncertainty = measurementMonteCarloFitUncertainty(specimen, fitResult, config)
%MEASUREMENTMONTECARLOFITUNCERTAINTY Propagate measurement uncertainty through refitting.
arguments
    specimen (1,1) struct
    fitResult (1,1) struct
    config (1,1) struct = mechanics.config.measurementMonteCarloFitConfig()
end

uncertainty = mechanics.fitting.geometryMonteCarloFitUncertainty( ...
    specimen, fitResult, config);
end
