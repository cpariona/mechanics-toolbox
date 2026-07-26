# Next-chat prompt

Copy the prompt below into a new chat when continuing repository development.

---

Quiero continuar el trabajo técnico en el repositorio:

`cpariona/mechanics-toolbox`

El PR #24 ya fue fusionado en `main`. La funcionalidad de tensión está completa y validada, `compareTensileStudies` es el entrypoint mantenido para comparar estudios completos, y el pipeline legacy por filas fue eliminado.

La validación posterior al merge confirmó que:

- comparar la misma data contra sí misma produce diferencias nulas;
- incrementar de forma controlada la fuerza en 10% produce aproximadamente 10% de incremento en esfuerzo y módulo tangente;
- al reutilizar un dataset preextraído no deben reaplicarse exclusiones u overrides por índice que ya estén reflejados en ese dataset.

La exportación y reporte de comparaciones quedó diferida en el issue #25. La posible incorporación futura del modelo Ogden también queda fuera del alcance actual.

## Nuevo objetivo general

Evaluar y diseñar la unificación de tensión y compresión bajo una arquitectura uniaxial compartida.

Quiero compartir importación, normalización de unidades, preparación fuerza-desplazamiento, cálculo de esfuerzo-deformación, selección engineering/true, evolución de área, módulo tangente, fitting constitutivo, incertidumbre, análisis poblacional y comparación de grupos siempre que sus contratos sean realmente comunes.

Deben permanecer separados los comportamientos específicos, entre ellos:

- tensión: interpretación de pico y post-pico, elongación y métricas propias;
- compresión: selección de ciclo, rama loading/unloading, contacto, histéresis, disipación, pandeo o colapso descriptivo y reporting específico.

No quiero duplicar funciones solo para conservar nombres de tensión o compresión, pero tampoco quiero forzar una gran abstracción genérica si los contratos todavía divergen.

## Convención de signos que debe evaluarse

La alternativa preferida para el estado mecánico interno es:

```text
tensión:
  displacement > 0
  strain > 0
  stress > 0
  stretch > 1

compresión:
  displacement < 0
  strain < 0
  stress < 0
  0 < stretch < 1
```

El equipo puede reportar compresión con fuerza y desplazamiento positivos. Esa convención instrumental debe distinguirse de la convención física almacenada.

Los gráficos y reportes pueden mostrar compresión como magnitud positiva, pero esa decisión de presentación no debe modificar los datos mecánicos internos.

Actualmente `runCompressionStudy` normaliza la compresión como magnitud positiva y luego invierte strain y stress para el fitting. Debes rastrear este comportamiento completo antes de proponer cambios.

## Antes de proponer cambios

1. Ejecuta `git fetch origin --prune`.
2. Confirma que la rama local `main` coincide exactamente con `origin/main`.
3. Reporta:
   - SHA local de `main`;
   - SHA de `origin/main`;
   - `git status -sb`;
   - los últimos cinco commits relevantes.
4. No descartes archivos locales ni no rastreados.
5. Lee, en este orden:
   - `README.md`
   - `docs/README.md`
   - `docs/development/context-handoff.md`
   - `docs/development/repository-structure.md`
   - `docs/development/testing.md`
   - `docs/workflows/tensile-study.md`
   - `docs/workflows/compression-study.md`
   - `docs/data/import-and-processing.md`
   - `docs/reference/constitutive-models.md`
   - `docs/reference/population-and-group-analysis.md`
   - `docs/reference/tensile-input-contracts.md`
6. Revisa únicamente los contratos adicionales necesarios para comprender el objetivo. Empieza por:
   - `processUniaxialSpecimen`
   - `computeUniaxialMeasures`
   - `tensionConfig`
   - `compressionConfig`
   - `runTensileStudy`
   - `runCompressionStudy`
   - `analyzeExtractedDataset`
   - `analyzeSpecimenPopulation`
   - `compareTensileStudies`
   - contratos de fitting y conversión de medidas constitutivas relacionados.

## Auditoría requerida

Identifica de forma concreta:

1. qué funciones ya son verdaderamente uniaxiales y compartidas;
2. qué funciones son genéricas en comportamiento pero conservan naming de tensión;
3. qué funciones deben permanecer específicas de tensión o compresión;
4. dónde se transforma actualmente el signo de fuerza, desplazamiento, strain y stress;
5. cómo afectan esas transformaciones a:
   - engineering strain;
   - true strain;
   - engineering/nominal stress;
   - true stress;
   - stretch;
   - `areaScale` y evolución de área;
   - módulo tangente;
   - fitting hiperelástico;
   - incertidumbre;
   - población, comparación, plotting y exportación;
6. qué contratos públicos o tests dependen de compresión positiva como magnitud;
7. qué riesgo tendría migrar a signo físico interno;
8. cuál es la migración mínima que mejora uniformidad sin romper contratos innecesariamente.

## Alcance y fases

No modifiques archivos ni crees una rama durante la auditoría inicial.

Después del resumen, propón un máximo de tres fases pequeñas y ordenadas. La primera fase probablemente debe limitarse a formalizar y probar el contrato de signos alrededor de `computeUniaxialMeasures` y el preprocesamiento de compresión.

No empieces creando `runUniaxialStudy`, renombrando APIs públicas o generalizando `compareTensileStudies` antes de demostrar que existe un contrato común estable.

Cuando yo seleccione el alcance, crea una rama nueva desde `main`. El nombre candidato es:

```text
feature/uniaxial-tension-compression-unification
```

## Criterios de diseño

- comparte implementación cuando los contratos físicos y de datos sean iguales;
- mantén normalización instrumental e interpretación experimental fuera del núcleo mecánico común;
- separa convención instrumental, convención mecánica almacenada y convención gráfica;
- conserva la selección engineering/true y los métodos de evolución de área;
- evita wrappers o aliases innecesarios;
- no dupliques fitting, población o comparación cuando puedan componerse de forma segura;
- no mezcles tensión y compresión accidentalmente en un mismo análisis poblacional sin validación explícita;
- actualiza tests y documentación en la misma fase que cambie un contrato;
- ejecuta tests focalizados y después `run_all_tests()` cuando exista cambio funcional;
- no abras PR, no hagas merge y no modifiques `main` sin autorización explícita.

---