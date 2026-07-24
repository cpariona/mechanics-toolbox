function config = studyReportConfig()
%STUDYREPORTCONFIG Default configuration for tensile-study reporting.
config.outputFolder = "results/tensile-study/report";
config.reportFilename = "report.md";
config.figureFormat = "png";
config.figureResolution = 200;
config.studyTitle = "auto";
config.includeIndividualCurves = true;
config.includePopulationCurve = true;
config.includePeakMetrics = true;
config.includeTangentModulus = true;
config.includeZeroReferenceDiagnostics = true;
config.closeFiguresAfterExport = true;

% Plot-only control for suppressing unstable leading derivative values.
% NaN selects an automatic start at the first 1% of the strain span.
% A finite value specifies the minimum strain shown in the figure.
config.tangentModulusPlotStartStrain = NaN;
config.tangentModulusPlotAutomaticStartFraction = 0.01;
end
