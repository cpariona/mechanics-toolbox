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

function testUnitLabelFormatting(testCase)
verifyEqual(testCase, ...
    mechanics.plotting.formatUnitLabel("Tangent modulus", "MPa"), ...
    "Tangent modulus [MPa]");
verifyEqual(testCase, ...
    mechanics.plotting.formatUnitLabel("Quantity", ""), ...
    "Quantity");
end
