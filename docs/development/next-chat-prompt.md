# Next-chat prompt

Copy the prompt below into a new chat after the phase-1 pull request has been merged.

---

Quiero continuar el trabajo técnico en el repositorio:

`cpariona/mechanics-toolbox`

La fase anterior incorporó un study driver ejecutable para ensayos de tensión, estandarizó el contexto constitutivo y separó el recorte visual del módulo tangente de su cálculo completo. Ese trabajo ya fue validado mediante:

- la suite completa de MATLAB;
- la ejecución del estudio real de tensión;
- la comprobación de que no quedan asignaciones activas a `inputMeasure` ni `outputStressMeasure`.

El siguiente objetivo general es desarrollar la fase 2 del estudio de tensión y realizar una limpieza posterior, pero todavía no quiero que modifiques archivos ni crees una rama hasta completar la verificación y seleccionar un alcance concreto.

## Antes de proponer cambios

1. Verifica el estado real del repositorio:

- ejecuta `git fetch origin --prune`;
- confirma que la rama local `main` coincide exactamente con `origin/main`;
- reporta el SHA local de `main`, el SHA de `origin/main`, `git status -sb` y los últimos cinco commits relevantes;
- no descartes archivos locales ni no rastreados.

2. Lee, en este orden:

- `README.md`
- `docs/README.md`
- `docs/development/context-handoff.md`
- `docs/development/repository-structure.md`
- `docs/workflows/tensile-study.md`
- `docs/development/tensile-study-follow-up.md`
- `studies/README.md`
- `studies/tension/run_tensile_experiment.m`

3. Lee únicamente los contratos y archivos de implementación adicionales necesarios para evaluar la fase 2. No recorras todo el repositorio sin una razón concreta.

4. Confirma que el estado persistente coincide con el repositorio real, especialmente:

- `context.deformationMeasure` y `context.stressMeasure` son los nombres vigentes;
- los valores predeterminados siguen siendo `"engineering-strain"` y `"nominal"`;
- `tangentModulus` conserva el cálculo completo;
- `tangentModulusForPlot` solo elimina la región inicial para visualización;
- los study drivers reales pertenecen a `studies/`;
- `processBatchManifest` todavía no comparte el contrato de resultado de `runTensileStudy`.

## Fase 2 pendiente

Evalúa estos bloques:

1. población de módulo tangente mediante malla común, interpolación y bootstrap;
2. figuras de parámetros nativos separadas por modelo y parámetro;
3. figura del módulo cortante inicial derivado por espécimen;
4. modelo de consenso del estudio basado en elegibilidad, BIC mediano, estabilidad y parsimonia;
5. unificación de workbook, lista de archivos, dataset preextraído y manifest bajo un único contrato de estudio de tensión.

La unificación de entradas es el bloque más arquitectónico y puede quedar en una rama independiente.

## Resultado esperado de esta primera conversación

Sin modificar archivos todavía:

- resume el estado actual del estudio de tensión;
- verifica la viabilidad de cada bloque pendiente contra la implementación real;
- identifica dependencias, duplicaciones y riesgos;
- propone un orden de implementación;
- recomienda un máximo de tres objetivos siguientes, ordenados por prioridad;
- delimita el primer objetivo en una rama y alcance pequeños;
- separa claramente implementación funcional y limpieza posterior.

No abras un PR ni hagas merge. Espera mi decisión antes de crear la nueva rama.

## Criterios de trabajo

- prioriza simplicidad y reutilización de contratos existentes;
- no añadas wrappers ni aliases de compatibilidad;
- evita incorporar toda la fase 2 al core workflow si puede mantenerse como composición;
- no crees nuevas funciones de plotting si un entrypoint mantenido puede extenderse;
- no elimines APIs basándote únicamente en conteos de consumidores;
- conserva source, studies, examples, tests y docs en sus responsabilidades actuales;
- ejecuta tests focalizados durante el desarrollo y la suite completa antes de cualquier merge;
- valida finalmente con `studies/tension/run_tensile_experiment.m` y datos reales representativos.

La limpieza final debe iniciarse después de que la fase 2 esté funcionalmente completa y validada.

---