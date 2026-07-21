# Selected-model parameter population summaries

Phase 23 converts the selected model from each successful Phase 22 specimen into a long-form parameter table.

```matlab
population = mechanics.workflow.summarizeSelectedParameters(batch);
```

Main outputs:

- `parameterTable`: one row per specimen and selected-model parameter;
- `overallSummary`: descriptive statistics by model and parameter;
- `groupSummary`: descriptive statistics by group, model, and parameter;
- `extractionErrors`: specimen-level extraction failures.

The long-form representation supports different selected models with different parameter sets. Parameters are never averaged across different names or model families.

When bootstrap uncertainty is available in the selected Phase 20 analysis, its lower, median, and upper parameter estimates are retained in `parameterTable`.

Export:

```matlab
mechanics.io.exportSelectedParameterPopulation( ...
    population, "results/selected-parameter-population");
```

The summaries are descriptive. Group hypothesis testing and multiplicity control remain separate operations.
