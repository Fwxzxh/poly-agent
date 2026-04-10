# Poly Agent: Modular AI Framework

Poly es un framework de agentes de IA modular y extensible escrito en **Gleam**, diseñado para ejecutarse sobre la v1beta de la API de Google Gemini (soporta "Thinking" y Function Calling).

## Arquitectura del Proyecto

- **Core (`src/agent.gleam`)**: Implementa el actor de Gleam (OTP) que gestiona el estado de la conversación y el bucle de razonamiento.
- **Providers (`src/providers/`)**: Capa de abstracción para LLMs. Actualmente implementa `gemini.gleam`.
- **Tools (`src/tools/`)**: Herramientas individuales que el agente puede ejecutar:
  - `fs.gleam`: Lectura, escritura, listado (recursivo) y búsqueda (`grep`) de archivos.
  - `shell.gleam`: Ejecución de comandos del sistema.
  - `net.gleam`: Peticiones HTTP GET.
  - `system.gleam`: Información del host (SO, arquitectura).
- **Skills (`src/skills/`)**: Agrupaciones lógicas de herramientas. `developer.gleam` agrupa las herramientas de sistema de archivos, shell y red.
- **Common (`src/common/types.gleam`)**: Definiciones de tipos compartidos para mensajes, partes (texto, pensamientos, llamadas a funciones) y eventos.

## Configuración

El agente se configura mediante variables de entorno (ver `.env.example`):
- `GOOGLE_API_KEY`: Requerida para la API de Gemini.
- `GOOGLE_MODEL`: Modelo a utilizar (por defecto `gemini-3.1-flash-lite-preview`).
- `VERBOSE`: Si es `true`, muestra los resultados crudos de las herramientas en la CLI.
- `DEBUG`: Activa logs detallados de las peticiones/respuestas HTTP.

## Capacidades de Razonamiento

Poly utiliza el modelo de razonamiento de Gemini para planificar sus acciones. El flujo es:
1. El usuario envía un mensaje.
2. El agente entra en un `run_reasoning_loop`.
3. El modelo genera pensamientos ("Thinking") y, si es necesario, llamadas a herramientas.
4. Las herramientas se ejecutan localmente y sus resultados se devuelven al modelo.
5. El proceso se repite (hasta un máximo de 10 pasos) hasta obtener una respuesta final.

## Desarrollo y Pruebas

- **Compilación**: `gleam build`
- **Ejecución**: `gleam run`
- **Pruebas**: `gleam test` (incluye pruebas unitarias para herramientas y lógica de agentes)

## Filosofía
Poly busca ser un agente de terminal ligero pero potente, siguiendo los principios de seguridad (manejo de errores robusto) y extensibilidad (facilidad para añadir nuevas herramientas a través de `ToolBuilder`).
