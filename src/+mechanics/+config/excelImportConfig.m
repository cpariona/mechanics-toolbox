function config = excelImportConfig()
%EXCELIMPORTCONFIG Default configuration for one-specimen table import.
config.sheet = 1;
config.dataRange = "";
config.forceColumns = ["Force", "Force_N", "Load", "Load_N", "Fuerza"];
config.displacementColumns = [ ...
    "Displacement", "Displacement_mm", "Extension", ...
    "Extension_mm", "Desplazamiento"];
config.timeColumns = ["Time", "Time_s", "Tiempo"];
config.currentAreaColumns = [ ...
    "CurrentArea", "CurrentArea_mm2", "Area", "Area_mm2", ...
    "CrossSectionArea", "CrossSectionArea_mm2"];
config.specimenId = "";
config.forceScale = 1;
config.displacementScale = 1;
config.timeScale = 1;
config.currentAreaScale = 1;
config.currentAreaUnit = "mm2";
config.normalizeCurrentAreaUnits = true;
config.preserveVariableNames = true;
end
