# mechanics-toolbox — instrucciones para agentes

Antes de modificar código, leer el estándar común fijado en `.research-automation/standards/engineering.md`. Si falta el submódulo privado, detener la edición e inicializarlo; no sustituirlo por una copia informal o una URL de `main`.

## Contratos locales

- `src/+mechanics/` contiene implementación mantenida; `studies/` drivers experimentales, `examples/` ejemplos y `tests/` pruebas. El mapa de propietarios y APIs está en [estructura](docs/development/repository-structure.md).
- Estudios completados tienen un resultado canónico. Comparaciones y caracterización conjunta lo consumen, sin repetir importación, segmentación ni fitting de datos crudos.
- `mechanics.models.modelRegistry` posee identidades, parámetros y cantidades derivadas. `yeoh-second-order` y `yeoh-third-order` son modelos registrados distintos; `yeoh` es solo el nombre de la familia/evaluador, no un alias compatible.
- Mantener contratos separados para configuración de espécimen, fitting, estudio y reportes. No cambiar defaults del conjunto de candidatos por refactorizaciones no científicas.
- Valores y unidades almacenados no se infieren de etiquetas de plots. `mechanics.io` es dueño de serialización de reportes, y `mechanics.plotting` de conversión de unidades de presentación.
- Datos experimentales y resultados generados en `data/` y `results/` no se comiten.
- Para verificar, `startup; results = run_all_tests();` y el protocolo mantenido en [testing](docs/development/testing.md).
- Consultar [context-handoff](docs/development/context-handoff.md) cuando se necesite conocer un asunto abierto; Git/PRs mantienen la cronología.

