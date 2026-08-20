# AlquilaMatch 🏠

##  Información General

- **Materia:** Interacción Hombre Computador ELC106-SA
- **Tipo de Proyecto:** Aplicación móvil de "Match Inmobiliario" (Filtro estricto entre inquilinos y propietarios)
- **Modalidad:** Vibe coding / Desarrollo asistido con IA

##  Integrantes

- Gabriel Mamani Sandoval
- Daniel Joaquin Mamani Peña

##  Problema Inicial

El proceso de búsqueda y oferta de alquileres genera una enorme pérdida de tiempo y frustración por la falta de transparencia y filtros. Por un lado, los inquilinos pierden tardes enteras visitando físicamente departamentos que no cumplen lo prometido en el anuncio (fotos desactualizadas, precios distintos o reglas ocultas como "no se aceptan mascotas"). Por otro lado, los propietarios publican en redes sociales (como grupos de Facebook) y reciben decenas de mensajes de WhatsApp sin filtro, perdiendo tiempo respondiendo a personas que no leyeron el anuncio o no califican.

## Índice de documentos

| Documento | Versión | Actor / alcance |
|---|---|---|
| [Brief inicial](brief/brief-v0.1.md) | v0.1 | Planteamiento original |
| [**Brief revisado**](brief/brief-v0.2.0.md) | **v0.2.0** | Hipótesis actual, alcance y preguntas abiertas |
| [Evidencias](research/evidencias.md) | — | 11 evidencias (A: inquilino · B: propietario) + patrones y contra-evidencia |
| [Guía de entrevistas](research/guia-entrevistas.md) | — | Instrumento para la validación con usuarios reales |
| [Persona — Marta](persona/persona-v0.1.md) | v0.1 | 🟦 Propietaria que publica |
| [App map](appmap/appmap-v0.1.md) | v0.1 | 🟦 Lado propietario |
| [Flujo — publicar un inmueble](flujo/flujo-v0.1.md) | v0.1 | 🟦 Marta publica y deja de repetirse |

Se documenta primero el **lado de la oferta**: hasta que no haya anuncios cargados no hay nada que buscar. El lado de la inquilina que busca es la v0.2.

## Estructura del repositorio

```
/
├── README.md
├── brief/
│   ├── brief-v0.1.md
│   └── brief-v0.2.0.md
├── research/
│   ├── evidencias.md
│   └── guia-entrevistas.md
├── persona/
│   └── persona-v0.1.md          # Marta, la propietaria
├── appmap/
│   └── appmap-v0.1.md           # lado propietario
└── flujo/
    └── flujo-v0.1.md            # publicar un inmueble
```

## Estado

- **Brief v0.2.0** — hipótesis revisada. La evidencia actual es preliminar y está declarada como simulada; la validación con usuarios reales está pendiente (ver `research/guia-entrevistas.md`).
- **Persona, App map y Flujo v0.1** — **el propietario que publica**. La persona es Marta, dueña de una casa con cuatro habitaciones cerca de la UAGRM; el flujo es publicar un inmueble (habitación, departamento o casa) declarando por adelantado las condiciones de descarte, más el ciclo de vida del anuncio hasta marcarlo *Ya alquilado*.
- Los diagramas están en Mermaid y se renderizan directamente en GitHub.

### Próximos pasos

1. **v0.2** — persona, app map y flujo de la inquilina que busca, y mapa completo de los dos lados.
2. **Entrevistas con usuarios reales** (ambos lados) para reemplazar la evidencia simulada.
3. **Implementación** — app móvil en Flutter con backend en Django.

---

> **Nota:** el repositorio conserva el nombre `PetConnect` por su origen. El proyecto fue reorientado al dominio de alquiler de vivienda; el historial de la propuesta anterior sigue disponible en los commits previos.
