function comparison = compareCompressionStudies(studies, groupLabels, config)
%COMPARECOMPRESSIONSTUDIES Compare completed compression studies by group.
arguments
    studies struct
    groupLabels string
    config (1,1) struct = mechanics.config.compressionStudyComparisonConfig()
end
comparison = mechanics.workflow.compareUniaxialStudies( ...
    studies, groupLabels, config, "compression");
end
