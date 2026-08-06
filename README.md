# Mercancía SaaS (en construcción)

Esta es la evolución multi-cliente de **Mercancía**: en lugar de una app para un
solo negocio, cada negocio ("tenant") se registra, configura sus propios
productos y usa la app con su propio equipo (dueño + operadores), con 14 días
de prueba gratis.

> **La versión original de un solo negocio sigue viva** en el repositorio
> [`pattialberto1/mercancia`](https://github.com/pattialberto1/mercancia)
> y en producción en https://pattialberto1.github.io/mercancia/ — esto no
> la toca ni la reemplaza.
>
> Esta versión SaaS vive en su propio repositorio y su propia dirección:
> **https://pattialberto1.github.io/mercancia-saas/**

## Estado actual

- ✅ **Esquema de datos y configuración de Supabase** — completo, probado y documentado
  en [`supabase/schema.sql`](./supabase/schema.sql) y [`supabase/SETUP.md`](./supabase/SETUP.md).
  Proyecto real ya creado y conectado.
- ✅ **Login y registro** — crear negocio (dueño), unirse con código (operador),
  iniciar/cerrar sesión, sesión persistente entre recargas, banner de prueba de
  14 días, código de invitación visible para el dueño. Probado en vivo por el
  dueño contra el proyecto real.
- ✅ **El equipo entra sin correo electrónico** — los repartidores y encargados
  de sitio se registran con un **usuario y una contraseña**, nada más. Ver
  sección abajo.
- ✅ **Ajustes de productos** — crear, editar, activar/desactivar, reordenar y
  eliminar productos; 3 plantillas rápidas (Pollo, a granel, pesada libre) para
  recrear la versión clásica sin escribir todo a mano; borrar un producto con
  historial se bloquea con un aviso claro (sugiere desactivar en su lugar).
- ✅ **Recepciones y pesadas** — pantalla de recepciones por producto y de
  pesadas dentro de cada una, generada automáticamente a partir de cómo esté
  configurado el producto (cestas, tara, rango, decimales, botones rápidos).
  Sincronización en tiempo real entre teléfonos del mismo negocio (Supabase
  Realtime) para las recepciones y las pesadas. Bloqueo real de nuevas
  recepciones/pesadas si el trial venció. Envío del resumen por WhatsApp.
- ✅ **Clientes y despachos** — además de recibir mercancía de proveedores, el
  negocio puede despachar a sus propios clientes, con precio por kg opcional
  en USD, tasa BCV del día (consultada sola, corregible a mano) y total a
  cobrar calculado solo en dólares y en bolívares. Ver sección abajo.
- ✅ **Reportes y exportación** — historial filtrable por tipo (recibido/
  despachado), producto y rango de fechas (con atajos "esta semana"/"este
  mes"/"todo"), con totales generales, por producto y por cliente. Exporta a
  CSV (se abre directo en Excel, con tildes/ñ correctos) o a PDF (imprimir/
  guardar como PDF desde el navegador), y también arma un resumen para
  enviar por WhatsApp. Ver sección abajo.
- ✅ **Alertas de discrepancia** — al pesar, cualquiera del equipo puede
  reportar un faltante, sobrante o mercancía en mal estado (con kg y nota
  opcionales) sin salir de la recepción/despacho. Un ícono ⚠️ con contador en
  el inicio lleva a la pantalla de Alertas, con las pendientes primero;
  resolverlas la puede el dueño o quien la reportó. Ver sección abajo.
- ✅ **Funciona sin conexión** — la app abre y deja trabajar aunque el
  teléfono no tenga señal: no pide volver a iniciar sesión, se ven los
  productos, clientes e historial guardados, y todo lo que se registre se
  sube solo en cuanto vuelve internet. **También el catálogo de productos**
  (crear, editar, activar/desactivar y reordenar). Ver sección abajo.
- ✅ **Tu equipo** — el dueño ve quién puede entrar a la app de su negocio,
  le cambia la contraseña a quien la olvidó y saca a quien ya no trabaja
  ahí, todo desde la app y sin entrar al panel de Supabase. Ver sección
  abajo.

### El equipo entra sin correo electrónico

Pedir correo era una traba real: muchos repartidores y encargados de sitio
simplemente no tienen uno. Ahora:

- **El dueño** se registra con **correo** real. Es el único que lo necesita,
  y le sirve para recuperar su contraseña solo si se le olvida.
- **El equipo** (operadores) se registra con el código de invitación, un
  **usuario** y una **contraseña**. Nada más. La app lo dice explícitamente
  en el formulario y en la tarjeta de invitación del dueño.
- **Al iniciar sesión** el campo acepta las dos cosas: si lleva arroba se
  toma como correo, si no, como usuario.

Por debajo Supabase igual necesita un correo para identificar cada cuenta,
así que a los usuarios se les arma uno interno (`juan@mercancia.local`) que
no existe, nunca recibe nada y no se muestra en pantalla — la persona solo
ve su usuario. Por eso **"Confirm email" tiene que quedar desactivado** en
Supabase: si no, esas cuentas esperarían una confirmación imposible (está
avisado en [`supabase/SETUP.md`](./supabase/SETUP.md)).

Los usuarios son únicos entre todos los negocios, así que si alguien elige
uno ya tomado la app lo dice claro y sugiere agregarle el apellido. Las
cuentas viejas creadas con correo siguen funcionando igual.

Si a alguien del equipo se le olvida la contraseña, **el dueño se la cambia
desde la app** (👥 Ver equipo → 🔑 Contraseña): pone una nueva, se la dice, y
listo. Ver la sección siguiente.

Probado con Playwright (25 verificaciones): que el formulario cambie según
quién se registre, que se rechace un correo donde va un usuario (y al
revés), usuarios muy cortos o con espacios, que por debajo se arme el
correo interno correcto, que se pueda iniciar sesión escribiendo solo el
usuario, que el dominio interno no se muestre nunca en pantalla, y los
mensajes de usuario repetido y contraseña incorrecta.

### Tu equipo (solo el dueño)

Desde el inicio, **👥 Ver equipo** abre la lista de quién puede entrar a la
app del negocio, con su usuario y su rol. Sobre cada operador hay dos cosas:

- **🔑 Contraseña** — para cuando alguien la olvida. El dueño escribe una
  nueva (se ve mientras la escribe, a propósito, para poder dictársela), la
  anterior deja de servir y, si esa persona tenía la sesión abierta en algún
  teléfono, se le cierra.
- **Quitar** — saca a esa persona del negocio. Lo que ya registró se queda
  en el historial; si vuelve, puede unirse otra vez con el código de
  invitación. A quien saquen, la app se lo dice la próxima vez que abra
  (y le borra del teléfono los datos del negocio) en lugar de dejarlo
  trabajando contra una copia que ya nadie va a recibir.

Al dueño no se le puede cambiar la contraseña ni quitar desde aquí: un
negocio sin dueño quedaría sin nadie que lo administre.

**Cómo funciona por dentro, que es la parte delicada.** Cambiarle la
contraseña a otra persona normalmente exige la llave de administrador del
proyecto, y esa llave **no puede estar dentro de la app**: cualquiera la
sacaría del navegador y tomaría control de todos los negocios. Por eso el
cambio lo hace una función que vive en el servidor
([`resetear_clave_operador`](./supabase/migrations/0006_equipo.sql)), que
corre con permisos elevados pero comprueba ella misma, en cada llamada, que
quien la invoca sea el dueño del **mismo** negocio y que el destinatario sea
un **operador** de ese negocio. La app solo lleva la llave pública.

Probado contra Postgres real: el dueño cambia la clave y la nueva sirve
mientras la vieja deja de servir; un operador intentándolo con otro
operador, el dueño de otro negocio, un dueño contra otro dueño y una
llamada sin sesión iniciada son **los cuatro rechazados**, y la clave
queda intacta. Más 34 verificaciones de la pantalla con Playwright.

### Clientes y despachos

El inicio tiene un selector **📥 Recepciones / 📤 Despachos**. Un despacho
usa exactamente la misma mecánica de pesadas que una recepción (cestas,
tara, rango, botones rápidos, WhatsApp, tiempo real) — la diferencia es que
al crearlo pregunta **"¿Para qué cliente?"**, con un cuadro de texto que
sugiere los clientes ya usados (se guardan solos la primera vez que se
escribe un nombre nuevo, no hace falta crearlos a mano) y una opción de
agregar uno nuevo si no está en la lista.

**Tocar un producto lleva siempre al historial**, tanto en recepciones como
en despachos: primero se ve lo de hoy y lo de días anteriores, y desde ahí
se decide. El movimiento nuevo se crea con **"+ Nueva recepción"** /
**"+ Nuevo despacho"** — que es también donde se pregunta por el cliente.
Si ya hay algo abierto hoy de ese producto (y del mismo cliente, en
despachos), ese botón entra ahí en vez de crear otro: dos movimientos
abiertos a la vez del mismo pedido terminarían repartiendo las pesadas
entre los dos. Para registrar algo aparte, se termina primero el abierto.

Cada despacho sigue siendo de **un solo producto** — si despachas Pollo y
Papas al mismo cliente el mismo día, son dos despachos separados, igual que
hoy una recepción es de un solo producto. El historial y el resumen de
WhatsApp de un despacho muestran el nombre del cliente.

En la base de datos, un despacho **es** una recepción con `tipo='despacho'`
y un `client_id` (en vez de una tabla aparte) — así toda la mecánica ya
construida y probada (RLS, trial, tiempo real) aplica sin duplicar nada.
Ver [`supabase/migrations/0002_despachos.sql`](./supabase/migrations/0002_despachos.sql).

Probado con Playwright (20 verificaciones): elegir un cliente nuevo desde
cero, que aparezca en la lista desplegable la próxima vez, que despachos y
recepciones normales no se mezclen en los historiales, que reutiliza el
despacho abierto de hoy para el mismo cliente en vez de duplicarlo, y que
crea uno nuevo si el anterior ya se cerró.

### Precio por kg en los despachos (USD y bolívares)

Dentro de un despacho (no aplica a recepciones) hay una tarjeta opcional
**💰 Precio** con un campo de precio por kg **en dólares**. En cuanto se
llena, aparece el **total a cobrar en USD** (peso neto × precio), y se
recalcula solo si se agregan, corrigen o borran pesadas — no hay que
volver a escribir nada. El precio lo puede poner o corregir quien creó el
despacho o el dueño (misma regla que ya protegía las recepciones,
reutilizada tal cual). El total aparece también en el resumen de
WhatsApp, y los reportes suman el monto facturado por producto y por
cliente, además de los kg.

El cálculo del total (`monto`) vive en la vista `reception_summary`, para
que nunca quede desactualizado si se corrige una pesada después. Ver
[`supabase/migrations/0003_precio_despacho.sql`](./supabase/migrations/0003_precio_despacho.sql).

> ⚠️ **Si la app dice que no se pudo guardar el precio**, a la base le
> faltan los dos campos (`precio_kg` y `tasa_bcv`): pasa cuando el proyecto
> de Supabase se creó antes de que existiera esta función. Se arregla
> pegando **[`supabase/migrations/0005_ponerse_al_dia.sql`](./supabase/migrations/0005_ponerse_al_dia.sql)**
> completo en *Supabase → SQL Editor → Run*. Es seguro correrlo aunque ya
> esté aplicado, y al terminar avisa *"Todo al día"*. La app detecta ese
> caso y lo dice en pantalla en vez de un "no se pudo guardar" a secas;
> mientras tanto las pesadas se siguen guardando con normalidad.

Probado contra Postgres real (7 verificaciones): el monto se calcula bien
y se recalcula solo con pesadas nuevas, y que solo quien creó el despacho
(o el dueño) puede cambiarle el precio — otro operador del mismo negocio
no puede, verificado a nivel de RLS. Probado con Playwright (13
verificaciones): la tarjeta de precio solo aparece en despachos, el total
se calcula y recalcula en vivo, se puede quitar el precio, y el resumen de
WhatsApp y los Reportes lo reflejan correctamente.

Junto al precio en USD, la app trae **sola** la tasa BCV del día (desde
[dolarapi.com](https://dolarapi.com), fuente pública) y muestra también el
**total en bolívares**. La tasa se consulta una vez por día (se guarda en
caché en el propio teléfono para no volver a pedirla en cada pantalla) y
se puede corregir a mano en cualquier momento con el botón "🔄 Actualizar
tasa" — si la consulta automática falla por lo que sea, la app avisa
claramente y deja escribirla a mano, nunca deja a la persona sin poder
cobrar. La tasa que quede guardada en cada despacho es la que estaba
vigente en ese momento (no se recalcula sola después), para que el
histórico de reportes en bolívares no cambie si la tasa sube o baja más
adelante. Ver
[`supabase/migrations/0004_tasa_bcv.sql`](./supabase/migrations/0004_tasa_bcv.sql).

Probado contra Postgres real (3 verificaciones): el monto en bolívares se
calcula bien y queda `null` si falta el precio o la tasa. Probado con
Playwright (16 verificaciones): la tasa se consulta sola al abrir un
despacho nuevo, se guarda en caché para no volver a pedirla el mismo día,
un despacho que ya tiene tasa fijada no la vuelve a consultar al
reabrirlo, el botón de actualizar funciona, y si la consulta falla la app
avisa y deja escribirla a mano sin romper nada.

### Reportes y exportación

Se apoya en la vista `reception_summary` del esquema (ya filtrada por RLS:
cada negocio solo ve la suya, y ya trae tipo y cliente desde la migración
de despachos). El ícono 📊 del inicio abre el historial con filtros
combinables (tipo, producto, rango de fechas) y atajos de rango rápido;
muestra totales generales, por producto y por cliente (para despachos, con
el monto facturado en USD y en Bs cuando se cargó precio por kg), y
exporta a CSV con BOM UTF-8 (para que Excel muestre bien tildes y ñ), a PDF
usando la función de imprimir del navegador, o arma un resumen para
WhatsApp.

Probado con Playwright (16 verificaciones): filtros por tipo/producto/fecha
combinados, atajos de rango, totales generales y por cliente, exportación a
CSV con nombre de archivo correcto, que el botón de PDF llama a
`window.print()`, y el contenido del resumen de WhatsApp.

### Alertas de discrepancia

Reutiliza la tabla `discrepancies` que ya existía en el esquema desde la
fase 1 (no hizo falta ninguna migración). Desde cualquier recepción o
despacho, el ícono ⚠️ abre un formulario corto: tipo (faltante / sobrante /
mal estado), kg de diferencia y una nota, ambos opcionales. Cualquiera del
equipo puede reportar una (igual que cualquiera puede registrar una
pesada); resolverla la puede el dueño o quien la reportó — está protegido
también a nivel de base de datos (RLS), no solo escondiendo el botón.

En el inicio, el ícono ⚠️ lleva un contador rojo con las discrepancias sin
resolver (para que no se pierdan en el historial general) y abre la
pantalla de Alertas, que lista las pendientes primero, con el producto, la
fecha, los kg y la nota de cada una, y un botón para marcarla resuelta (o
reabrirla si fue un error).

Probado contra Postgres real (6 verificaciones de RLS): un operador puede
reportar y resolver la suya, pero no puede borrarla (solo el dueño puede);
aislamiento total entre negocios, incluyendo que un negocio no puede
resolver una discrepancia ajena aunque lo intente directo por la API.
Probado con Playwright (18 verificaciones): reportar desde una recepción,
el contador del inicio aparece/desaparece según haya pendientes, la lista
de Alertas muestra tipo/producto/kg/nota, y marcar resuelta / reabrir.

### Funciona sin conexión

En un depósito o en la calle la señal se cae, y la app tiene que seguir
sirviendo igual. Hay dos piezas:

**No te saca la sesión.** Antes, sin señal la app mandaba al login y no
dejaba entrar — pero la persona nunca había cerrado sesión: lo que pasaba
es que sin internet Supabase no puede renovar el token de acceso (vence
cada hora) y avisaba como si la sesión no existiera. Ahora, si el teléfono
ya tiene los datos del negocio guardados y no hay red, la app entra
directo al inicio con ellos. Solo se va al login si de verdad se cierra
sesión (y ahí sí avisa antes si queda algo sin subir).

**No se pierde nada de lo que registres.** Todo lo que se ve del servidor
queda guardado en el propio teléfono (negocio, productos, clientes,
historial), y lo que se registre sin señal se guarda en una cola y se sube
solo en cuanto vuelve internet — sin tener que apretar nada. Una barra
arriba avisa si no hay conexión y cuántos registros quedan por subir, y
las filas que todavía no se subieron salen marcadas «sin subir».

Sin señal funcionan: entrar, ver el negocio y los productos, crear
recepciones y despachos, pesar, borrar pesadas, terminar/reabrir, anotar
clientes nuevos, poner precio, reportar discrepancias, ver los reportes
(que se calculan con el historial guardado) y **cambiar el catálogo de
productos** (crear, editar, activar/desactivar, reordenar).

Lo único que **sí** necesita conexión es **borrar** un producto: si ya
tiene recepciones registradas no se puede borrar, y el único que lo sabe
es el servidor. Encolarlo dejaría al dueño creyendo que lo borró para
verlo reaparecer al sincronizar, así que la app prefiere decirlo de una
vez. (Y registrarse por primera vez, claro, que también lo hace el
servidor.)

Lo delicado de esto es que algo creado sin señal (por ejemplo un cliente
nuevo) todavía no tiene su identificador real del servidor. La app le
pone uno temporal y, al sincronizar, lo cambia por el definitivo en todo
lo que dependía de él, para que un despacho hecho offline quede ligado a
su cliente correcto y sus pesadas a su despacho correcto.

**La tasa BCV también se guarda.** Se consulta una vez al día al abrir la
app con señal (no en cada despacho), y queda guardada indefinidamente: si
mañana no hay internet, se sigue usando la última conocida, avisando de
qué día es por si conviene corregirla a mano.

Probado con Playwright simulando una desconexión real —red caída de
verdad, no solo un aviso— con 36 verificaciones: recargar la app sin señal
no manda al login y conserva negocio/productos/historial; se puede crear un
despacho completo offline (cliente nuevo incluido), pesarlo y ponerle
precio; los reportes se arman con el historial local; y al volver la señal
se sube todo solo, quedando cada cosa ligada a lo que corresponde (se
verifica que no quede ningún identificador temporal en el servidor).

Probado con Playwright simulando PostgREST (33 verificaciones): crear
recepción, botones rápidos, selector de cestas, rango proporcional, aviso
de peso fuera de rango, totales, borrar pesada, terminar/reabrir, WhatsApp,
producto a granel con decimales, producto de pesada libre (sin tara ni
cestas), y el bloqueo real por trial vencido tanto al crear una recepción
como al intentar registrar una pesada. Lo único que **no** se pudo probar
desde aquí es la sincronización en tiempo real en sí (requiere una conexión
real a Supabase que esta caja de desarrollo no tiene) — el código sigue el
patrón documentado de Supabase Realtime y no genera errores al conectarse/
desconectarse, pero la prueba con dos teléfonos de verdad la tienen que
hacer ustedes.

### Navegación

Tocar un producto en el inicio lleva a su **historial** — lo abierto de hoy
y lo de días anteriores — tanto en recepciones como en despachos. Desde ahí
se entra a lo que ya está abierto con un toque, o se crea uno nuevo con
**"+ Nueva recepción" / "+ Nuevo despacho"** (que es donde se pregunta por
el cliente, en despachos).

Antes tocar un producto entraba directo a pesar, creando el movimiento si
no había ninguno abierto. Se cambió porque en el uso real sorprendía: al
elegir un cliente para despachar, la app saltaba a un despacho nuevo sin
dar oportunidad de ver antes lo que ya había registrado.

El botón de crear sigue **reutilizando** lo que esté abierto hoy de ese
producto (y del mismo cliente, en despachos) en vez de duplicarlo: dos
movimientos abiertos a la vez del mismo pedido terminarían repartiendo las
pesadas entre los dos. Para registrar algo aparte, se termina primero el
que está abierto.

### Cómo funciona el rango de peso con menos cestas

Para productos de "varias cestas" (como el Pollo, 2 cestas · 65–75 kg), si
una pesada se hace con menos cestas de las normales, el rango esperado se
ajusta **proporcional** al número de cestas de esa pesada (ej. con 1 cesta,
65–75 kg pasa a 32,5–37,5 kg). Es un cambio de diseño respecto a la versión
clásica (que guardaba dos rangos totalmente independientes para 2 cestas y
para 1 cesta) — más simple de configurar (un solo rango por producto) y
matemáticamente consistente en vez de dos números escritos a mano que se
podían desincronizar.

### Qué quedó probado de la parte de login

Se probó con Playwright simulando las respuestas reales de Supabase (esta caja
de desarrollo no tiene salida a internet hacia el proyecto real, así que esta
es la verificación más profunda posible desde aquí — el primer inicio de
sesión real contra el proyecto en vivo todavía lo tienen que hacer ustedes):

- Login correcto e incorrecto, con sus mensajes de error.
- Crear negocio nuevo (dueño) y quedar con sesión iniciada al instante.
- Unirse con código de invitación válido → queda ligado al negocio correcto;
  con código inválido → mensaje de error claro.
- El operador no ve el código de invitación (solo el dueño).
- El banner cambia correctamente según los días de prueba restantes o vencidos.
- La sesión persiste al recargar la página, y el logout limpia todo.

De paso aparecieron y se corrigieron **dos bugs reales** antes de subir esto:
una recursión infinita en las políticas de seguridad de `memberships`, y un
error en la función que cambia de pantalla que dejaba la app trabada en
"Cargando…" para todo el mundo.

## Qué cambia respecto a la versión clásica

| Clásica (rama `claude/chicken-receiving-app-8z1rs2`) | SaaS (esta rama) |
|---|---|
| Un solo negocio | Muchos negocios (tenants), cada uno con sus datos separados |
| 3 pestañas fijas (Pollo, Papas, Verduras) | Productos configurables por cada negocio |
| PIN compartido (`7070`) | Cuenta propia por persona: el dueño con correo, el equipo con usuario y contraseña (sin correo) |
| Sincronización vía token de GitHub | Supabase (Postgres + Auth + Realtime) |
| Sin roles | Dueño vs. operador, con permisos distintos |
| Sin límite de uso | Prueba de 14 días, luego requiere activación manual |
| Solo recepción de proveedores | Recepción de proveedores **y** despacho a clientes propios (con autocompletado, precio por kg en USD y total en USD/Bs a la tasa BCV del día) |
| — | Reportes filtrables por tipo/producto/fecha, exportables a Excel/PDF/WhatsApp |
| — | Alertas de discrepancia (faltante/sobrante/mal estado), visibles para todo el equipo |
| — | Funciona sin señal: no saca la sesión y sube solo lo registrado al volver internet |

## Cómo seguir

Están cubiertas las 7 fases planeadas originalmente, más el precio en
USD/Bs de los despachos y el modo sin conexión. Con eso el producto está
completo para usarse a diario.

### Pendiente, decidido para más adelante

- **Cobros dentro de la app** (que el negocio pague su suscripción desde el
  teléfono). Hoy, cuando a un negocio se le vence la prueba de 14 días, la
  activación se hace a mano en Supabase: `update tenants set is_paid = true
  where id = '…'`. Sirve mientras sean pocos negocios; con varios clientes
  se vuelve trabajo manual todas las semanas.

### Límites que se quedan así a propósito

- **Registrarse (cuenta nueva) necesita internet** — solo la primera vez;
  después la app abre y trabaja sin señal. No hay forma de evitarlo: crear
  la cuenta la hace el servidor.
- **Borrar un producto necesita conexión.** Crear, editar, activar/desactivar
  y reordenar funcionan sin señal; borrar no, porque si el producto ya tiene
  recepciones el único que lo sabe es el servidor, y encolarlo dejaría al
  dueño creyendo que lo borró para verlo reaparecer al sincronizar.

## Instalarla en el teléfono

La app es una **PWA**: se instala desde el navegador, sin tiendas, sin
revisiones de Apple ni de Google, y sin que nadie cobre comisión. Se agrega
a la pantalla de inicio y abre a pantalla completa como cualquier otra app.

Los dos sistemas no se instalan igual, y no hay forma de unificarlo, así
que la app detecta dónde está y dice lo que toca:

| | Cómo se instala |
|---|---|
| **Android** (Chrome) | La app muestra un botón **Instalar** que abre el diálogo del propio navegador. Un toque. |
| **iPhone** (Safari) | No existe ese botón en iOS: hay que usar **Compartir ⬆️ → «Añadir a pantalla de inicio»**. La app lo explica con esos dos pasos. |
| **iPhone** (Chrome, Firefox…) | No pueden instalar nada — en iOS solo Safari expone esa opción. La app avisa de que hay que abrirla en Safari. |

El aviso sale en la pantalla de acceso (que es donde llega alguien nuevo) y
dentro de la app, tiene un **«Ahora no»** que se respeta, y desaparece solo
en cuanto la app está instalada.

Para que Android acepte instalarla hacen falta cuatro cosas, y las cuatro
están: servirse por **HTTPS**, un **manifiesto** con nombre e iconos de 192
y 512 px, `display: standalone`, y un **service worker** que responda a las
peticiones. Hay además un icono **maskable** (con margen), porque Android
recorta el icono en círculo y sin ese margen se comía el pico del gallo.

## Cambiar la dirección (quitar el `github.io`)

La app no depende de GitHub para nada: son archivos estáticos y **todas las
rutas del manifiesto son relativas**, así que funciona igual en cualquier
dominio sin tocar una línea de código.

Para usar un dominio propio con GitHub Pages (sigue siendo gratis; solo se
paga el dominio, ~10–15 $ al año):

1. Comprar el dominio (Namecheap, Porkbun, Cloudflare…).
2. En el DNS del dominio, crear un registro **CNAME** del subdominio que
   quieras (por ejemplo `app`) apuntando a **`pattialberto1.github.io`**.
   Si quieres usar el dominio pelado (`midominio.com`), en vez del CNAME
   van cuatro registros **A** a las IPs de GitHub Pages: `185.199.108.153`,
   `185.199.109.153`, `185.199.110.153`, `185.199.111.153`.
3. En el repositorio: **Settings → Pages → Custom domain**, escribir el
   dominio y **Save**. Eso crea un archivo `CNAME` en la raíz del repo.
4. Esperar a que aparezca el check verde y marcar **Enforce HTTPS**. El
   certificado lo emite GitHub solo, gratis; puede tardar unos minutos.

Como son dos apps en dos repositorios, van en dos subdominios distintos
(por ejemplo `app.midominio.com` para el SaaS y `pollo.midominio.com` para
la versión clásica). Cada repositorio lleva su propio dominio.

> ⚠️ **Hazlo antes de que la gente empiece a usarla, no después.** El
> navegador guarda los datos **por dirección**: la sesión, el historial
> descargado y sobre todo **la cola de lo registrado sin señal** viven
> atados a `pattialberto1.github.io`. Al cambiar de dominio, un teléfono
> que tuviera pesadas sin subir las perdería, y la app instalada en la
> pantalla de inicio seguiría apuntando a la dirección vieja (hay que
> borrarla y volver a instalarla). Con la app recién estrenada esto no
> cuesta nada; con tres meses de uso, sí.
>
> Después del cambio hay que actualizar el **Site URL** en Supabase
> (*Authentication → URL Configuration*), que es el que usan los enlaces de
> recuperación de contraseña del dueño.

## Estructura

- `index.html` — toda la app: login, registro, marco autenticado, Ajustes
  de productos, recepciones/despachos y pesadas, Reportes, y Alertas.
- `vendor/supabase.js` — cliente de Supabase empaquetado en el propio repo
  (no depende de un CDN externo en cada carga; para actualizarlo:
  `npm install @supabase/supabase-js@latest` en cualquier carpeta y copiar
  `node_modules/@supabase/supabase-js/dist/umd/supabase.js` aquí encima).
- `supabase/schema.sql` — esquema completo, para un proyecto nuevo desde cero.
- `supabase/migrations/` — cambios incrementales para un proyecto que ya
  tiene `schema.sql` aplicado (ver `supabase/SETUP.md`).
- `supabase/SETUP.md` — guía de alta del proyecto de Supabase.
