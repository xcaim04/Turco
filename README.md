# Turco

Aplicación Flutter para Android que gestiona los turnos de una peluquería mixta.
La usa el personal del salón para registrar clientes, programar turnos con un
estilista y llevar la agenda diaria.

Primer Examen Parcial · Programación para Dispositivos Móviles · Ingeniería Informática, 3er año.

- **Application id:** `com.carlosblanco.turco`
- **Nombre visible:** Turco
- **Flutter:** 3.44.9 (canal stable), Dart 3.12.2

No usa servidor, base de datos, almacenamiento local ni autenticación: todos los
datos viven en memoria y se cargan al iniciar desde los datos de prueba de
`lib/data/seed_data.dart`. Las fechas de los turnos se calculan a partir de
`DateTime.now()`, así que los datos nunca quedan vencidos.

## Inicializar y ejecutar

Hace falta Flutter 3.44 o superior con el SDK de Android, y un emulador o un
teléfono Android conectado.

```bash
git clone <url-del-repositorio>
cd turco_entrega1
flutter pub get
flutter run
```

Para pasar el analizador y los tests:

```bash
flutter analyze
flutter test
```

## Generar el APK release

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Como `build/`
no se sube al repositorio, el APK se publica en los Releases de GitHub.

## Funcionalidades

| Pantalla | Ruta | Qué hace |
| --- | --- | --- |
| Agenda (inicial) | `/agenda?estilista=ID` | Tira semanal con `ListView.builder`, resumen del día, filtros por estilista y estado, acciones rápidas con pulsación larga. |
| Clientes | `/clientes` | Lista con `ListView.separated`, búsqueda sin acentos, filtro por género, alta, edición y baja en hojas inferiores. |
| Servicios | `/servicios` | Catálogo en `GridView.builder` de 2, 3 o 4 columnas según el ancho; tocar un servicio abre el formulario con ese servicio. |
| Estilistas | `/estilistas` | `CustomScrollView` con `SliverAppBar` plegable y `SliverList`; tocar un estilista abre la Agenda filtrada. |
| Detalle de turno | `/turno/:id` | Datos completos del turno, notas con scroll propio, editar, completar o cancelar. |
| Formulario de turno | `/turno/nuevo`, `/turno/:id/editar` | `Form` con validadores, cuadrícula de franjas de 30 minutos, `FocusNode` y aviso de cambios sin guardar (`PopScope`). |

La navegación usa solo `go_router`, con `StatefulShellRoute.indexedStack` para
las cuatro pestañas (cada una conserva su estado). Se usan parámetros de ruta,
parámetros de consulta, `extra` y retorno de valor con `context.pop(turno)`.

Reglas de negocio (en `lib/core/rules/reglas.dart`, el store y los ViewModels,
nunca en los widgets):

- El salón abre de lunes a sábado de 9:00 a 19:00; los turnos empiezan en franjas
  de 30 minutos y terminan a las 19:00 como máximo.
- Un estilista solo recibe turnos con servicios que realiza.
- Ni el estilista ni el cliente pueden tener dos turnos programados que se
  solapen; los cancelados no ocupan horario.
- No se crean ni reprograman turnos en el pasado. Solo los turnos programados se
  editan, completan o cancelan, y los turnos no se eliminan.
- El teléfono del cliente es único y tiene 8 dígitos. No se elimina un cliente
  con turnos programados.

## Estructura de carpetas

```
lib/
├── main.dart                  Punto de entrada
├── app.dart                   MaterialApp.router, tema y dependencias globales
├── core/
│   ├── app_scope.dart         InheritedWidget con el store y el tema
│   ├── router/                Rutas de go_router
│   ├── rules/                 Reglas de negocio puras (horario, solapes)
│   ├── theme/                 Tema claro y oscuro (fuente Poppins)
│   └── utils/                 Formato de fechas y validadores
├── data/
│   ├── in_memory_store.dart   Fuente de verdad en memoria (ChangeNotifier)
│   └── seed_data.dart         Datos de prueba
├── models/                    Servicio, Estilista, Cliente, Turno y enums
├── viewmodels/                Un ViewModel (ChangeNotifier) por pantalla
├── views/                     Pantallas (escuchan su ViewModel con ListenableBuilder)
└── widgets/                   Widgets reutilizables, hojas inferiores y diálogos
assets/
├── fonts/                     Poppins (licencia OFL)
└── images/                    Avatares de estilistas e imágenes de categorías
test/                          Tests de reglas, del formulario y de widgets
capturas/                      Capturas reales de la app en Android
```

## Arquitectura

MVVM sin paquetes externos de estado: cada pantalla crea su ViewModel
(`ChangeNotifier`) y lo escucha con `ListenableBuilder`. Todos los ViewModels
escuchan el `InMemoryStore`, de modo que un cambio en turnos o clientes se ve
enseguida en todas las pantallas.
