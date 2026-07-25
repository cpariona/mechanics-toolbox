%% TENSILE STUDY FROM A BATCH MANIFEST
% Minimal maintained example showing how manifest input enters the same
% runTensileStudy workflow and returns the same downstream study contract.

restoredefaultpath
clear classes
clear functions
clear
clc
close all

repositoryFolder = 'D:\Escritorio\mechanics-toolbox';
cd(repositoryFolder)
startup

manifestFile = fullfile( ...
    repositoryFolder, "data", "manifests", "tensile-study.csv");
outputFolder = fullfile( ...
    repositoryFolder, "results", "manifest-tensile-study");

config = mechanics.config.tensileStudyConfig();
config.input.type = "manifest";

% The manifest supplies specimen file, identifier, initial length, initial
% area, include flag, sheet, optional column preferences, and scaling.
config.datasetAnalysis.processingConfig.preprocessing.zeroReference.method = ...
    "preload-threshold";
config.datasetAnalysis.processingConfig.preprocessing.zeroReference.preloadForce = 0.10;
config.datasetAnalysis.fitting.enabled = true;
config.population.enabled = true;
config.export.enabled = true;
config.export.outputFolder = outputFolder;

study = mechanics.workflow.runTensileStudy(manifestFile, config);

summary = mechanics.workflow.summarizeTensileStudy(study);
disp(summary)
disp(study.analysis.summary)
disp(study.input)
disp(study.provenance)
