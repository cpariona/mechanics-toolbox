function comparison = compareTensileStudies(studies, groupLabels, config)
%COMPARETENSILESTUDIES Compare completed tensile-study results by group.
arguments
    studies struct
    groupLabels string
    config (1,1) struct = mechanics.config.tensileStudyComparisonConfig()
end
comparison = mechanics.workflow.compareUniaxialStudies( ...
    studies, groupLabels, config, "tension");
end
