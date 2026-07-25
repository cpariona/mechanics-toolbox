# Next-chat prompt

Copy the prompt below into a new chat when continuing repository maintenance.

---

Quiero continuar el trabajo técnico en el repositorio:

`cpariona/mechanics-toolbox`

La funcionalidad planificada para el estudio de tensión ya fue implementada y validada. El repositorio incluye población de esfuerzo y módulo tangente, comparación constitutiva por espécimen, parámetros seleccionados, módulo cortante inicial derivado, consenso de modelo, comparación de grupos y contratos de entrada unificados para workbook, lista de archivos, manifest y dataset preextraído.

El objetivo actual es mantenimiento final y validación más amplia con datos reales. No quiero que elimines APIs ni hagas cambios amplios antes de verificar el repositorio y justificar cada hallazgo.

## Antes de proponer cambios

1. Ejecuta `git fetch origin --prune` y confirma que `main` coincide exactamente con `origin/main`.
2. Reporta SHA local, SHA remota, `git status -sb` y los últimos commits relevantes.
3. Lee, en este orden:
   - `README.md`
   - `docs/README.md`
   - `docs/development/context-handoff.md`
   - `docs/development/repository-structure.md`
   - `docs/development/final-cleanup-audit.md`
   - `docs/development/tensile-study-follow-up.md`
   - `docs/workflows/tensile-study.md`
   - `docs/reference/tensile-input-contracts.md`
   - `docs/reference/population-and-group-analysis.md`
4. Revisa únicamente archivos adicionales necesarios para confirmar problemas concretos.

## Estado que debes confirmar

- `runTensileStudy` es el entrypoint end-to-end mantenido para tensión.
- Workbook, file list, manifest y dataset convergen al mismo contrato downstream.
- `processBatchManifest` es un procesador legacy por filas y no compara grupos.
- Los grupos experimentales se asignan después del procesamiento.
- La suite completa y el estudio real representativo pasaron en la fase anterior.

## Resultado esperado

- resume el estado actual;
- identifica duplicación concreta y configuraciones sin consumidores efectivos;
- distingue limpieza segura de cambios que requieren migración;
- no elimines `processBatchManifest` solo por solapamiento con manifests en `runTensileStudy`;
- propone un máximo de tres tareas siguientes, ordenadas por prioridad;
- crea una rama solo después de delimitar el primer alcance;
- no abras PR ni hagas merge sin autorización.

## Validación

Durante cualquier cambio:

- ejecuta tests focalizados;
- ejecuta `run_all_tests()` antes del PR;
- ejecuta `studies/tension/run_tensile_experiment.m` cuando cambie comportamiento funcional;
- revisa `git diff --check` y el estado del repositorio.

---
