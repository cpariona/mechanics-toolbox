function config = constitutiveStudyReportConfig()
%CONSTITUTIVESTUDYREPORTCONFIG Configure final constitutive-study reporting.
config.outputFolder = "results/constitutive-study-report";
config.reportFilename = "constitutive_study_report.md";
config.figureFormat = "png";
config.figureResolution = 200;
config.includeModelSelectionFigure = true;
config.includeParameterFigure = true;
config.includeInferenceFigure = true;
config.closeFiguresAfterExport = true;
config.significanceAlpha = 0.05;
end
