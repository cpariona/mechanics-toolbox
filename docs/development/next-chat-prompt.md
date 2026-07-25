# Next-chat prompt

Copy the prompt below into a new chat when continuing repository development.

---

Quiero continuar el trabajo técnico en el repositorio:

`cpariona/mechanics-toolbox`

La funcionalidad planificada para el estudio de tensión ya fue implementada y validada. El repositorio incluye población de esfuerzo y módulo tangente, comparación constitutiva por espécimen, parámetros seleccionados, módulo cortante inicial derivado, consenso de modelo, comparación de grupos y contratos de entrada unificados para workbook, lista de archivos, manifest y dataset preextraído.

El patrón experimental que quiero priorizar es un workbook por material o condición, con varias probetas dentro de cada workbook. Por ejemplo:

- un workbook de ECOFLEX 00-20 con cinco probetas;
- un workbook de ECOFLEX 00-50 con cinco probetas.

Cada workbook debe procesarse mediante `runTensileStudy`. Después quiero comparar los resultados completos de ambos estudios sin reprocesar las probetas.

## Objetivo técnico pendiente

Diseñar e implementar un workflow mantenido, tentativamente:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    [study0020, study0050], ...
    ["ECOFLEX 00-20", "ECOFLEX 00-50"], ...
    config);
```

Este workflow debe reutilizar la comparación poblacional y de grupos ya implementada, preservar los estudios originales y validar compatibilidad de medidas, unidades y resultados requeridos.

`processBatchManifest` es un procesador legacy por filas. Debe eliminarse después de que `compareTensileStudies` exista, sus casos útiles hayan sido migrados y la nueva ruta haya sido validada. No lo renombres para convertirlo en la función de comparación.

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
4. Revisa únicamente los contratos adicionales necesarios para diseñar la comparación entre estudios.

## Resultado esperado antes de modificar

- resume los contratos de `runTensileStudy` relevantes para comparación;
- identifica qué partes de `assignSpecimenGroups`, `analyzeGroupComparison`, `summarizeSelectedParameters` y `compareSelectedParametersBetweenGroups` pueden reutilizarse;
- define las verificaciones de compatibilidad entre estudios;
- propone un contrato pequeño para `compareTensileStudies`;
- delimita qué resultados entran en la primera versión y cuáles quedan opcionales;
- identifica exactamente qué archivos, configuraciones, exportadores y tests podrán eliminarse junto con `processBatchManifest`;
- crea una rama solo después de delimitar el alcance;
- no abras PR ni hagas merge sin autorización.

## Criterios de diseño

- no reproceses datos crudos ni repitas fitting si los resultados compatibles ya existen;
- preserva los estudios de entrada sin modificarlos;
- exige etiquetas de grupo explícitas;
- reutiliza funciones existentes antes de crear nuevas capas;
- separa comparación de respuestas mecánicas, parámetros constitutivos y modelos de consenso cuando sus contratos difieran;
- no conserves aliases de compatibilidad cuando se elimine `processBatchManifest`;
- elimina en la misma migración los tests exclusivos de contratos retirados;
- ejecuta tests focalizados, `run_all_tests()` y una validación real con dos workbooks antes del PR.

---
