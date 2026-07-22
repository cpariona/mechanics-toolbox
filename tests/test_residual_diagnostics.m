function tests = test_residual_diagnostics
tests = functiontests(localfunctions);
end

function setupOnce(~)
testFile = mfilename("fullpath");
repositoryRoot = fileparts(fileparts(testFile));
addpath(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));
end

function testDiagnosticShapes(testCase)
fitResult = localFitResult([0.02; -0.01; 0.03; -0.02; 0.01; ...
    -0.03; 0.02; 0.00; -0.01; 0.01]);

diagnostics = mechanics.fitting.analyzeFitResiduals(fitResult);

verifyEqual(testCase, diagnostics.observationCount, 10);
verifySize(testCase, diagnostics.standardizedResidual, [10, 1]);
verifyEqual(testCase, height(diagnostics.observationSummary), 10);
verifyEqual(testCase, height(diagnostics.metricSummary), 10);
verifyFalse(testCase, diagnostics.hasOutliers);
end

function testDeformationTrendIsDetected(testCase)
x = linspace(0, 1, 20)';
residual = 0.2 .* x - 0.1;
fitResult = localFitResult(residual, x);

diagnostics = mechanics.fitting.analyzeFitResiduals(fitResult);

verifyTrue(testCase, diagnostics.hasDeformationTrend);
verifyGreaterThan(testCase, diagnostics.deformationCorrelation, 0.99);
verifyTrue(testCase, diagnostics.hasSystematicStructure);
end

function testOutlierIsDetected(testCase)
residual = zeros(20, 1);
residual(10) = 5;
fitResult = localFitResult(residual);

config = mechanics.config.residualDiagnosticsConfig();
config.standardizedResidualThreshold = 2.5;
diagnostics = mechanics.fitting.analyzeFitResiduals(fitResult, config);

verifyTrue(testCase, diagnostics.hasOutliers);
verifyEqual(testCase, nnz(diagnostics.outlierMask), 1);
verifyTrue(testCase, diagnostics.outlierMask(10));
end

function testInsufficientObservationsRejected(testCase)
fitResult = localFitResult([0.1; -0.1; 0.05]);

verifyError(testCase, ...
    @() mechanics.fitting.analyzeFitResiduals(fitResult), ...
    "mechanics:fitting:InsufficientResidualObservations");
end

function testExportCreatesFiles(testCase)
fitResult = localFitResult(linspace(-0.05, 0.05, 12)');
diagnostics = mechanics.fitting.analyzeFitResiduals(fitResult);
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder));

files = mechanics.io.exportFitResidualDiagnostics(diagnostics, folder);

verifyTrue(testCase, isfile(files.observations));
verifyTrue(testCase, isfile(files.metrics));
verifyTrue(testCase, isfile(files.data));
end

function fitResult = localFitResult(residual, deformation)
residual = residual(:);
if nargin < 2
    deformation = linspace(0, 1, numel(residual))';
else
    deformation = deformation(:);
end

predictedStress = 2 .* deformation + 1;
measuredStress = predictedStress + residual;

fitResult.deformation = deformation;
fitResult.measuredStress = measuredStress;
fitResult.predictedStress = predictedStress;
fitResult.residuals = residual;
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
