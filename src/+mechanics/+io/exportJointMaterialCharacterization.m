function outputFiles = exportJointMaterialCharacterization(result, outputFolder)
%EXPORTJOINTMATERIALCHARACTERIZATION Export the maintained joint result bundle.
arguments
    result (1,1) struct
    outputFolder (1,1) string
end

required = ["candidateSummary","selectedModelName","selectedFit", ...
    "modeSummary","specimenSummary"];
if ~all(isfield(result, required))
    error("mechanics:io:InvalidJointMaterialCharacterization", ...
        "Provide a completed joint material-characterization result.");
end
folder = string(outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

candidateFile = fullfile(folder, "candidate_model_summary.csv");
writetable(result.candidateSummary, candidateFile);
outputFiles.candidateSummary = string(candidateFile);

parameterNames = string(result.selectedFit.parameterNames(:));
parameterValues = result.selectedFit.parameters(:);
selectedParameters = table(parameterNames, parameterValues, ...
    'VariableNames', {'Parameter','Estimate'});
parameterFile = fullfile(folder, "selected_joint_parameters.csv");
writetable(selectedParameters, parameterFile);
outputFiles.selectedParameters = string(parameterFile);

modeFile = fullfile(folder, "mode_fit_summary.csv");
writetable(result.modeSummary, modeFile);
outputFiles.modeSummary = string(modeFile);

specimenFile = fullfile(folder, "specimen_fit_summary.csv");
writetable(result.specimenSummary, specimenFile);
outputFiles.specimenSummary = string(specimenFile);

for modeIndex = 1:numel(result.modeNames)
    modeName = string(result.modeNames(modeIndex));
    figureHandle = mechanics.plotting.plotJointModeFit(result, modeName);
    cleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
    baseName = "joint_fit_" + modeName;
    imageFile = mechanics.plotting.exportFigureFiles( ...
        figureHandle, folder, baseName, "png", 200);
    outputFiles.(matlab.lang.makeValidName(modeName + "Figure")) = imageFile;
    outputFiles.(matlab.lang.makeValidName(modeName + "FigureFig")) = ...
        string(fullfile(folder, baseName + ".fig"));
    clear cleanup
end

matFile = fullfile(folder, "joint_material_characterization.mat");
save(matFile, "result");
outputFiles.result = string(matFile);

reportFile = fullfile(folder, "joint_material_characterization.md");
localWriteReport(reportFile, result, selectedParameters, outputFiles);
outputFiles.report = string(reportFile);
end

function localWriteReport(reportFile, result, selectedParameters, outputFiles)
fileId = fopen(reportFile, "w");
if fileId < 0
    error("mechanics:io:ReportFileOpenFailed", ...
        "Could not open report file: %s", reportFile);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>

fprintf(fileId, "# Joint material characterization\n\n");
fprintf(fileId, "Generated: %s\n\n", char(string(result.createdAt)));
fprintf(fileId, "Selected model: `%s`\n\n", ...
    char(string(result.selectedModelName)));
fprintf(fileId, "Modes: %s\n\n", ...
    char(strjoin(string(result.modeNames(:))', ", ")));

fprintf(fileId, "## Selected parameters\n\n");
mechanics.io.writeMarkdownTable(fileId, selectedParameters);
fprintf(fileId, "## Candidate models\n\n");
mechanics.io.writeMarkdownTable(fileId, result.candidateSummary);
fprintf(fileId, "## Mode fit summary\n\n");
mechanics.io.writeMarkdownTable(fileId, result.modeSummary);
fprintf(fileId, "## Specimen fit summary\n\n");
mechanics.io.writeMarkdownTable(fileId, result.specimenSummary);

fprintf(fileId, "## Interpretation boundaries\n\n");
fprintf(fileId, "- Tension and compression specimens are independent and unpaired.\n");
fprintf(fileId, "- The selected model is conditional on configured candidates, bounds, normalization, mode weights, and observed deformation ranges.\n");
fprintf(fileId, "- AIC and BIC are retained as pooled physical-error diagnostics; selection is governed by the hierarchical joint objective and parsimony contract.\n\n");

fprintf(fileId, "## Figures\n\n");
for modeIndex = 1:numel(result.modeNames)
    modeName = string(result.modeNames(modeIndex));
    figureField = matlab.lang.makeValidName(modeName + "Figure");
    if isfield(outputFiles, figureField)
        [~, name, extension] = fileparts(outputFiles.(figureField));
        fprintf(fileId, "### %s\n\n![%s joint fit](%s%s)\n\n", ...
            char(modeName), char(modeName), char(string(name)), char(string(extension)));
    end
end
end
