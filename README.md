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

### Investigación y definición

| Documento | Contenido |
|---|---|
| [Brief inicial](brief/brief-v0.1.md) | Planteamiento original |
| [**Brief revisado**](brief/brief-v0.2.0.md) | Hipótesis actual, alcance y preguntas abiertas |
| [Evidencias](research/evidencias.md) | 11 evidencias (A: inquilino · B: propietario), patrones y contra-evidencia |
| [Guía de entrevistas](research/guia-entrevistas.md) | Instrumento para la validación con usuarios reales |

### Flujo v0.1 — El propietario que publica 🟦

| Documento | Contenido |
|---|---|
| [Persona — Marta](persona/persona-v0.1.md) | Propietaria de 4 habitaciones cerca de la UAGRM |
| [App map](appmap/appmap-v0.1.md) | Módulos del lado propietario |
| [Flujo](flujo/flujo-v0.1.md) | Publicar un inmueble + ciclo de vida del anuncio |
| [**Wireframes**](wireframes/flujo-v0.1-propietario/flujo-completo.png) | Las 5 pantallas en una lámina — se ven sin abrir Figma |

### Flujo v0.2 — La inquilina que busca 🟩

| Documento | Contenido |
|---|---|
| [Persona — Andrea](persona/persona-v0.2.md) | Estudiante de provincia, con un gato |
| [App map](appmap/appmap-v0.2.md) | Mapa completo: los dos lados y dónde se enganchan |
| [Flujo](flujo/flujo-v0.2.md) | Buscar, ver anuncio y solicitar visita |
| [**Wireframes**](wireframes/flujo-v0.2-inquilina/flujo-completo.png) | Las 7 pantallas en una lámina — se ven sin abrir Figma |

### Diseño

| Documento | Contenido |
|---|---|
| [Lenguaje visual](wireframes/_lenguaje-visual.md) | Reglas que siguen todos los wireframes |
| [Wireframes del flujo v0.1](wireframes/flujo-v0.1-propietario/README.md) | Los 5 SVG del propietario |
| [Wireframes del flujo v0.2](wireframes/flujo-v0.2-inquilina/README.md) | Los 7 SVG de la inquilina |
| [**Decisión de diseño**](docs/decision-clase-05.md) | Jerarquía, layout y espaciado: antes, cambio, prueba con usuaria y siguiente paso |

### Implementación

| Documento | Contenido |
|---|---|
| [Mobile](mobile/README.md) | Flutter: estructura, autenticación y emulador |
| [Backend](backend/README.md) | Django + DRF: modelo de datos, API y pruebas |

## Estructura del repositorio

```
/
├── README.md
├── brief/            # el planteamiento y su revisión
├── research/         # evidencias y guía de entrevistas
├── persona/          # v0.1 propietario · v0.2 inquilina
├── appmap/           # v0.1 un lado · v0.2 los dos
├── flujo/            # v0.1 publicar · v0.2 buscar y solicitar
├── wireframes/       # SVG importables a Figma + lámina del flujo
├── docs/             # arquitectura y decisiones de diseño
├── mobile/           # app Flutter
└── backend/          # API Django + DRF
```

## Estado

- **Brief v0.2.0** — hipótesis revisada. La evidencia actual es preliminar y está declarada como simulada; la validación con usuarios reales está pendiente (ver `research/guia-entrevistas.md`).
- **Persona, App map y Flujo v0.1** — **el propietario que publica**. La persona es Marta, dueña de una casa con cuatro habitaciones cerca de la UAGRM; el flujo es publicar un inmueble (habitación, departamento o casa) declarando por adelantado las condiciones de descarte, más el ciclo de vida del anuncio hasta marcarlo *Ya alquilado*.
- Los diagramas están en Mermaid y se renderizan directamente en GitHub.

### Próximos pasos

1. **v0.2** — persona, app map y flujo de la inquilina que busca, y mapa completo de los dos lados.
2. **Entrevistas con usuarios reales** (ambos lados) para reemplazar la evidencia simulada.
3. **Implementación** — ver `mobile/README.md` y `backend/README.md`.

## Stack técnico

| Capa | Elección |
|---|---|
| App móvil | Flutter — ver [`mobile/`](mobile/README.md) |
| API | Django 6 + Django REST Framework — ver [`backend/`](backend/README.md) |
| Base de datos | PostgreSQL |
| Auth | JWT (`djangorestframework-simplejwt`) |

**Por qué móvil:** las tres acciones críticas dependen del teléfono — el propietario marca la ubicación parado en el inmueble y fotografía el estado actual en ese momento; la inquilina busca en la calle, entre clases (Brief v0.2.0 §6).

---

> **Nota:** el repositorio conserva el nombre `PetConnect` por su origen. El proyecto fue reorientado al dominio de alquiler de vivienda; el historial de la propuesta anterior sigue disponible en los commits previos.
