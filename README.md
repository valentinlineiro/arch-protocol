# ARCH Protocol

**"El mejor prompt es el que no se escribe."**

El caos de la IA no se arregla con mejor IA. Se arregla con mejor proceso.

---

## ¿Qué es ARCH?

**ARCH (Autonomous Routing & Context Hierarchy)** es un protocolo de disciplina para el desarrollo de software con IA. Está inspirado en el Sistema de Producción Toyota (TPS) y traduce sus principios al lenguaje de Git, prompts y agentes de IA.

**El problema que resuelve:**
Los asistentes de IA son rápidos pero caóticos. Escriben código sin saber qué archivos existen, empiezan refactorizaciones masivas sin un punto de control en Git, y no dejan rastro de qué cambiaron ni por qué. Terminas con código rápido y debugging lento.

**La solución:**
ARCH impone un flujo de trabajo de 7 pasos que Claude sigue en cada tarea — sin importar la urgencia que sientas. No es un "prompt mejor". Es un protocolo que hace que cualquier prompt funcione mejor.

---

## Los 7 Pasos de ARCH

| Paso | Qué obliga a hacer a Claude |
| :--- | :--- |
| **GATE** | Claude debe declarar con sus propias palabras el objetivo, los archivos y las restricciones **antes de escribir cualquier código**. Si no lo entiende, pregunta. Es un filtro de alucinación. |
| **ANCHOR** | Confirma que existe un commit de Git como punto de restauración antes de empezar. Sin red, no hay cambio. |
| **ATOM** | Si la tarea es grande (más de 5 archivos o 3 responsabilidades), sugiere dividirla en piezas más pequeñas (tamaño S/M/L). |
| **PULL** | Declara explícitamente qué archivos va a leer antes de escribir. Nada de contexto implícito. |
| **Generate** | Genera un único cambio lógico. Un commit por tarea. |
| **EYES** | Te recuerda que revises el `git diff` y no confíes en el resumen de la IA. La responsabilidad final es tuya. |
| **LOG** | Cierra cada tarea con una retrospectiva kaizen de 3 líneas: qué funcionó, qué falló, qué cambiarías. Esto crea un registro de aprendizaje que mejora las tareas futuras y te da datos para evolucionar tu propio proceso. |

---

## ¿Por qué funciona?

La mayoría de los problemas con el desarrollo asistido por IA no son problemas del modelo, sino **problemas de proceso**. Los mismos errores se repiten: contexto perdido, falta de red de seguridad en Git, tareas demasiado grandes para revisar, ausencia de memoria institucional.

ARCH toma la respuesta del TPS al mismo problema en la fabricación: **parar la línea antes de que los defectos se multipliquen**.

- **GATE** impide que Claude genere código que no pueda fundamentar.
- **ANCHOR** evita cambios irrecuperables.
- **LOG** crea un registro diario del que realmente puedes aprender.

El protocolo es deliberadamente resistente a la presión. Cuando dices *"escribe el arreglo rápido, tengo una demo en 2 horas"*, ARCH no obedece — ejecuta **GATE** primero, porque es exactamente en ese momento cuando saltárselo causa el mayor daño.

---

## ¿Por qué lo construí?

> *"Construí ARCH porque estaba harto de pasar más tiempo depurando código generado por IA que escribiéndolo. Después de 6 meses usándolo a diario, he reducido mis errores por pérdida de contexto en un 80%. Este es el protocolo que desearía haber tenido desde el primer día."*
>
> — Valentín Liñeiro, creador de ARCH.

---

## Instalación

Añade el marketplace y luego instala el plugin:

```bash
/plugin add-marketplace https://github.com/valentinlineiro/arch-protocol
/plugin install arch-protocol@arch-protocol
```

Para empezar a trabajar, simplemente invoca:

```bash
"Let's work on X using ARCH"
```

### ¿Qué esperar después de la instalación?

Una vez instalado, ARCH se ejecuta en segundo plano. Notarás que Claude comienza a pedir contexto antes de escribir código, y cada tarea termina con una pequeña retrospectiva. No tienes que pensar en ARCH — solo hace que tu asistente de IA se sienta más… profesional.

---

## El Manifiesto ARCH

> *"El mejor golpe es el que no se da.*
> *El mejor prompt es el que no se escribe.*
>
> *ARCH no es un prompt mejor.*
> *Es un protocolo que hace que cualquier prompt funcione mejor."*

---

## Comunidad y contribuciones

ARCH es abierto y está impulsado por la comunidad.

- **Pruébalo durante una semana.**
- Si te ahorra tiempo, abre un issue con tu caso de uso.
- Si no te ahorra tiempo, abre un issue contándome por qué. Estoy iterando basado en feedback real.

**Contribuciones y forks son bienvenidos.**

---

**Diseñado por Valentín Liñeiro.**
