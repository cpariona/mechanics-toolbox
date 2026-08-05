function tests = test_plotting_units
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testUnitsAreResolvedFromProcessedSpecimen(testCase)
specimen.processed.units.force = "kN";
specimen.processed.units.displacement = "cm";
specimen.processed.units.strain = "1";
specimen.processed.units.stress = "kPa";
specimen.processed.units.energy = "J";
record.status = "processed";
record.specimen = specimen;

units = mechanics.plotting.resolveStudyUnits(record);

verifyEqual(testCase, units.force, "kN");
verifyEqual(testCase, units.displacement, "cm");
verifyEqual(testCase, units.strain, "-");
verifyEqual(testCase, units.stress, "kPa");
verifyEqual(testCase, units.energy, "J");
end

function testFallbackUnitsAreAvailableWithoutProcessedRecords(testCase)
record.status = "failed";
record.specimen = struct();

units = mechanics.plotting.resolveStudyUnits(record);

verifyEqual(testCase, units.force, "N");
verifyEqual(testCase, units.displacement, "mm");
verifyEqual(testCase, units.strain, "-");
verifyEqual(testCase, units.stress, "MPa");
verifyEqual(testCase, units.energy, "mJ");
end

function testMechanicalDisplayUnits(testCase)
verifyEqual(testCase, mechanics.plotting.mechanicalDisplayUnit( ...
    "deformation", "-"), "mm/mm");
verifyEqual(testCase, mechanics.plotting.mechanicalDisplayUnit( ...
    "deformation", "1"), "mm/mm");
verifyEqual(testCase, mechanics.plotting.mechanicalDisplayUnit( ...
    "stress", "kPa"), "kPa");
verifyEqual(testCase, mechanics.plotting.mechanicalDisplayUnit( ...
    "normalized-rmse", "MPa"), "-");
end

function testGenericUnitLabelDoesNotInferQuantity(testCase)
verifyEqual(testCase, ...
    mechanics.plotting.formatUnitLabel("Tangent modulus", "MPa"), ...
    "Tangent modulus [MPa]");
verifyEqual(testCase, ...
    mechanics.plotting.formatUnitLabel("Engineering strain", "-"), ...
    "Engineering strain [-]");
verifyEqual(testCase, ...
    mechanics.plotting.formatUnitLabel("Quantity", ""), ...
    "Quantity");
end

function testMechanicalAxisLabelsOwnMechanicalPresentation(testCase)
verifyEqual(testCase, mechanics.plotting.mechanicalAxisLabel( ...
    "deformation", "engineering-strain", "-"), ...
    "Engineering strain [mm/mm]");
verifyEqual(testCase, mechanics.plotting.mechanicalAxisLabel( ...
    "stress", "nominal", "MPa"), ...
    "Nominal stress [MPa]");
verifyEqual(testCase, mechanics.plotting.mechanicalAxisLabel( ...
    "objective", "", "MPa"), ...
    "Objective [-]");
end

function testStressStrainPlotUsesDisplayUnitsWithoutChangingData(testCase)
curve.strain = [0; 0.1; 0.2];
curve.stress = [0; 1; 2];
curve.units.strain = "-";
curve.units.stress = "kPa";

figureHandle = mechanics.plotting.plotStressStrain(curve);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
axesHandle = findobj(figureHandle, "Type", "axes");
lineHandle = findobj(axesHandle, "Type", "line");

verifyEqual(testCase, string(axesHandle.XLabel.String), "Strain [mm/mm]");
verifyEqual(testCase, string(axesHandle.YLabel.String), "Stress [kPa]");
verifyEqual(testCase, lineHandle.XData(:), curve.strain);
verifyEqual(testCase, lineHandle.YData(:), curve.stress);
end
