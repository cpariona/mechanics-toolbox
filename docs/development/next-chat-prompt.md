# Next-chat prompt

Copy the prompt below into a new chat when continuing repository development.

---

Quiero continuar el trabajo técnico en el repositorio:

`cpariona/mechanics-toolbox`

La comparación inicial entre estudios de tensión ya fue implementada mediante:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    studies, groupLabels, config);
```

Cada material o condición se procesa primero con `runTensileStudy`. La comparación consume los resultados completos, valida compatibilidad de medidas y unidades, preserva los estudios originales, evita colisiones entre identificadores y reutiliza la comparación poblacional y de grupos existente.

El pipeline legacy por filas fue eliminado:

```text
processBatchManifest
summarizeBatchResults
batchProcessingConfig
exportBatchSummary
test_batch_processing
```

Manifest continúa siendo una entrada válida de `runTensileStudy` mediante `validateBatchManifest` y `readBatchManifest`.

## Antes de proponer cambios

1. Ejecuta `git fetch origin --prune` y confirma que `main` coincide exactamente con `origin/main`.
2. Reporta SHA local, SHA remota, `git status -sb` y los últimos commits relevantes.
3. Lee, en este orden:
   - `README.md`
   - `docs/README.md`
   - `docs/development/context-handoff.md`
   - `docs/development/repository-structure.md`
   - `docs/development/final-cleanup-audit.md`
   - `docs/workflows/tensile-study.md`
   - `docs/reference/tensile-input-contracts.md`
   - `docs/reference/population-and-group-analysis.md`
   - `docs/workflows/constitutive-analysis.md`
4. Revisa únicamente los contratos adicionales necesarios para el objetivo seleccionado.

## Estado que debes confirmar

- `runTensileStudy` es el entrypoint para un estudio individual.
- `compareTensileStudies` es el entrypoint para comparar estudios completos.
- La comparación inicial cubre curvas poblacionales y métricas mecánicas escalares.
- Los estudios de entrada no se reprocesan ni se modifican.
- El pipeline legacy por filas ya no existe.
- Manifest permanece soportado dentro de `runTensileStudy`.

## Posibles objetivos siguientes

- comparar parámetros constitutivos seleccionados entre estudios;
- comparar módulo cortante inicial derivado;
- comparar modelos de consenso;
- añadir exportación y reporte específicos para la comparación;
- validar con dos workbooks reales de materiales distintos.

## Criterios de diseño

- reutiliza resultados mantenidos antes de recalcular;
- preserva los estudios de entrada;
- exige etiquetas explícitas y únicas;
- evita wrappers de compatibilidad para APIs eliminadas;
- separa comparación mecánica, parámetros constitutivos y consenso cuando sus contratos difieran;
- ejecuta tests focalizados, `run_all_tests()` y validación real cuando cambie comportamiento funcional;
- no abras PR ni hagas merge sin autorización.

---
