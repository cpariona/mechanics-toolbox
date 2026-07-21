function config = workbookExtractionConfig()
%WORKBOOKEXTRACTIONCONFIG Default workbook-extraction configuration.
config.extractor = "auto";
config.customExtractor = [];
config.defaultInitialLength = NaN;

config.zwick.resultsSheet = "Resultados";
config.zwick.specimenSheetPattern = "^Probeta\s+\d+$";
config.zwick.specimenTitleRow = 1;
config.zwick.variableNamesRow = 2;
config.zwick.unitsRow = 3;
config.zwick.dataStartRow = 4;

config.zwick.resultsHeaderRow = 1;
config.zwick.resultsUnitsRow = 2;
config.zwick.resultsDataStartRow = 3;
config.zwick.resultsSheetNameColumn = 1;
config.zwick.specimenIdColumn = 2;
config.zwick.thicknessColumn = 3;
config.zwick.widthColumn = 4;

config.zwick.displacementAliases = [ ...
    "Deformación", "Deformation", "Displacement", ...
    "Extension", "Desplazamiento"];
config.zwick.forceAliases = [ ...
    "Fuerza estándar", "Standard force", "Force", ...
    "Load", "Fuerza"];

config.generic.sheet = 1;
config.generic.dataRange = "";
config.generic.specimenId = "";
config.generic.initialLength = NaN;
config.generic.initialArea = NaN;
end
