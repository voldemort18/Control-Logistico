# Operación Dunkirk — Seguimiento de electores

App de una sola página (HTML/JS puro, sin build) para cargar electores y ver el
avance en un dashboard. Login de usuario único. Datos guardados en Supabase
(Postgres + Auth), desplegada en Netlify desde GitHub.

## 1. Crear el proyecto en Supabase

1. Entrá a https://supabase.com → **New project**. Anotá la contraseña de la
   base (no es la que usa el usuario de la app, es la del admin de Postgres).
2. Cuando el proyecto termine de crearse, andá a **SQL Editor → New query**.
   Tenés dos formas de cargar el esquema (elegí una):
   - **Todo junto**: pegá el contenido de `schema.sql` (de esta carpeta) y
     corré **Run**.
   - **Por migraciones** (recomendado si vas a usar el CLI de Supabase o
     Supabase conectado a GitHub): corré, en orden, el contenido de cada
     archivo dentro de `supabase/migrations/`:
     1. `20260827000001_masters.sql`
     2. `20260827000002_electores.sql`
     3. `20260827000003_upgrade_existing_electores.sql` — **solo** si ya
        habías corrido una versión vieja de `schema.sql` que tenía "master"
        como campo de texto suelto en electores. Si es la base nueva, este
        archivo no hace nada (es seguro correrlo igual).

   Esto crea las tablas `masters` y `electores` (con `electores.master_id`
   apuntando a `masters`) y seguridad a nivel de fila (RLS), así que solo un
   usuario logueado puede leer y escribir.
3. Andá a **Authentication → Users → Add user** y creá el usuario:
   - Email: `vperalta@operaciondunkirk.com`
   - Password: `12345678`
   - (podés cambiar el email/contraseña cuando quieras, ver paso 4)
4. Andá a **Settings → API** y copiá dos valores:
   - **Project URL**
   - **anon public key**

## 2. Configurar el frontend

Abrí `index.html` y reemplazá estas dos líneas cerca del final del archivo:

```js
const SUPABASE_URL = "https://TU-PROYECTO.supabase.co";
const SUPABASE_ANON_KEY = "TU-ANON-KEY";
```

con los valores que copiaste del paso 4. La `anon key` es pública por diseño
(es la que usa cualquier frontend de Supabase) — la seguridad real la da la
política RLS de la tabla, que exige estar logueado.

Si cambiás el email del usuario en Supabase, actualizá también el mapeo cerca
de esas líneas:

```js
const USER_EMAIL_MAP = {
  "vperalta": "vperalta@operaciondunkirk.com"
};
```

Esto es lo que permite que en la pantalla de login se escriba simplemente
`Vperalta` como usuario en vez de un email completo.

## 3. Subir a GitHub

Desde esta carpeta:

```bash
git init
git add .
git commit -m "Operación Dunkirk - app de seguimiento de electores"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/TU-REPO.git
git push -u origin main
```

(Creá el repo vacío en GitHub antes del último paso, sin README ni licencia,
para que no choque con este `git push`.)

## 4. Desplegar en Netlify

1. En https://app.netlify.com → **Add new site → Import an existing project**.
2. Elegí GitHub y el repositorio que acabás de crear.
3. Build command: dejalo vacío. Publish directory: `.` (ya está en
   `netlify.toml`, así que Netlify lo detecta solo).
4. **Deploy**. En un par de minutos tenés la URL pública (algo como
   `operacion-dunkirk.netlify.app`), que podés renombrar desde
   **Site settings → Change site name**.

Cada vez que hagas `git push` a `main`, Netlify vuelve a desplegar solo.

## 5. (Opcional) Aplicar las migraciones automáticamente desde GitHub

La carpeta `supabase/migrations/` sigue el formato estándar del **Supabase
CLI**, así que además de pegar el SQL a mano en el paso 1 podés conectar el
repo directamente a tu proyecto de Supabase:

1. Instalá el CLI: `npm install -g supabase` (o `brew install supabase/tap/supabase`).
2. Desde esta carpeta: `supabase login`, después `supabase link --project-ref TU-PROJECT-REF`
   (el project-ref está en Settings → General de tu proyecto Supabase).
3. `supabase db push` — aplica las migraciones de `supabase/migrations/` en orden.
4. Si preferís que se aplique solo en cada push a GitHub, en Supabase andá a
   **Project Settings → Integrations → GitHub** y conectá este repositorio:
   Supabase corre las migraciones nuevas automáticamente cuando le hacés
   merge a la rama `main`.

Cualquier cambio de esquema que hagamos de ahora en más va a venir como un
archivo nuevo dentro de `supabase/migrations/` (nunca modificando los viejos),
para que el historial quede prolijo y aplicable tanto a mano como con el CLI.

## Login

- Usuario: `Vperalta`
- Contraseña: `12345678`

(Se pueden cambiar en cualquier momento desde Supabase → Authentication →
Users → editar el usuario.)

## Pestaña "Masters"

Mantenimiento completo de masters: agregar, editar y borrar. Cada master
tiene nombre y teléfono. Al borrar un master que ya tiene electores
cargados, la app avisa cuántos electores quedan "sin master asignado" (no
borra los electores, solo desvincula el master).

## Campos que se cargan por elector

Master (se elige de una lista, viene de la pestaña Masters), elector,
teléfono del elector, voto (a favor / indeciso / en contra / no define),
colegio electoral, móvil asignado, chofer + teléfono.

## Pestaña "Listado"

Master es la columna principal (primera columna) de la tabla. Hay un
filtro desplegable para ver solo los electores de un master puntual, más un
buscador libre por elector / colegio / chofer / nombre de master.

## Dashboard

- Totales: electores cargados, colegios electorales con datos, cantidad "a
  favor", cantidad sin master asignado.
- Gráfico de barras: avance de carga por colegio electoral.
- Gráfico de anillo: distribución del voto (a favor / indeciso / en contra /
  no define).

## Notas

- Es de un solo usuario a propósito: cualquiera con el usuario/contraseña
  entra y ve/edita todo. Si más adelante necesitás varios usuarios con
  distintos permisos, se puede extender agregando más usuarios en Supabase
  Auth y ajustando las políticas RLS.
- Las opciones del campo "Voto" están en el `<select>` de `index.html`
  (buscá `<option>A favor</option>`); se pueden editar ahí directamente.
- Los masters ahora viven en su propia tabla (`masters`), separada de
  `electores`, y se relacionan por `master_id`. Esto es lo que permite
  editar un master en un solo lugar y que se refleje en todos sus electores,
  y filtrar el listado por master.
