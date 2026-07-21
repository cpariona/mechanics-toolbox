# Phase 26 scope

Phase 26 is the final consolidation and release-readiness phase for the current mechanics-toolbox roadmap.

Included:

- independent fracture-detection threshold in `fractureAnalysisConfig`;
- removal of the fracture-analysis dependency on segmentation configuration;
- enforcement of `fractureAnalysisConfig.enabled` in the workflow;
- regression tests for disabled analysis and threshold independence;
- explicit documentation of force-displacement energy units and sign convention;
- complete repository test-suite validation as the release gate;
- final maintenance documentation.

Not included:

- new constitutive models;
- mixed-effects or hierarchical modeling;
- new experimental file formats;
- automatic scientific interpretation;
- a dedicated dissipated-fracture-energy model;
- changes to established public workflows outside the maintenance scope.
