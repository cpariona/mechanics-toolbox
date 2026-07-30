function mode = jointCharacterizationModeRegistry(modeName)
%JOINTCHARACTERIZATIONMODEREGISTRY Return one supported mode contract.
arguments
    modeName (1,1) string
end

name = lower(strtrim(modeName));
switch name
    case "tension"
        mode.name = "tension";
        mode.expectedTestType = "tension";
        mode.deformationField = "strain";
        mode.stressField = "stress";
        mode.expectedDeformationSign = "nonnegative";
        mode.expectedStressSign = "nonnegative";
    case "compression"
        mode.name = "compression";
        mode.expectedTestType = "compression";
        mode.deformationField = "strain";
        mode.stressField = "stress";
        mode.expectedDeformationSign = "nonpositive";
        mode.expectedStressSign = "nonpositive";
    otherwise
        error("mechanics:workflow:UnsupportedJointCharacterizationMode", ...
            "Unsupported joint-characterization mode: %s.", modeName);
end
end
