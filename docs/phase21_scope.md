# Phase 21 scope

Phase 21 adds reliability-aware comparison and selection across multiple
constitutive models for one dataset.

Included:

- execution of the Phase 20 workflow for every candidate model;
- per-model fit and reliability summaries;
- AIC, AICc, BIC, RMSE, and normalized-RMSE criteria;
- exclusion of reliability-ineligible models from ranking;
- configurable continuation after individual model failures;
- selected-model reporting;
- plotting, export, tests, documentation, and example.

Not included:

- batch execution across multiple specimens;
- cross-validation or held-out predictive testing;
- automatic changes to parameter bounds;
- automatic observation removal;
- statistical comparison between experimental groups.
