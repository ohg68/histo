# Despliegue de Toonflow en Railway

Guía para desplegar **Toonflow** (AI 短剧工厂) en [Railway](https://railway.app) usando el `Dockerfile` incluido.

Railway detecta el `Dockerfile` automáticamente (reforzado por `railway.json`), ejecuta `yarn build` durante la construcción y arranca el backend con `node data/serve/app.js`.

---

## 1. Variables de entorno

Configúralas en **Railway → tu servicio → Variables**.

| Variable   | Valor recomendado | Obligatoria | Notas |
|------------|-------------------|-------------|-------|
| `PORT`     | `10588`           | Recomendada | Puerto en el que escucha el backend. Railway suele inyectar su propio `PORT`; la app ahora lo respeta (con fallback a `10588`). Si defines uno, asegúrate de que el *target port* del dominio público apunte al mismo valor. |
| `NODE_ENV` | `prod`            | Sí          | Activa el modo producción. **Ojo:** el valor es `prod`, no `production` (así lo espera el código de Toonflow). Ya viene fijado en el `Dockerfile`, pero puedes sobrescribirlo aquí. |
| `ossURL`   | `https://<tu-dominio-railway>` | Opcional | URL pública base para servir los assets estáticos (imágenes/videos generados). Solo aplica si sirves archivos por HTTP y necesitas URLs absolutas. En el código la variable se lee como `ossURL` (minúsculas); en la doc oficial aparece como `OSSURL`. Déjala vacía si no la necesitas. |

> Las **API keys de los proveedores de IA no van aquí** (ver sección 4).

---

## 2. Volumen persistente

Toonflow escribe en runtime la **base de datos SQLite** (`db2.sqlite`) y los **archivos generados/subidos** (`oss/`). Todo lo escribible se consolida bajo `/app/data/storage`. Sin un volumen ahí, **esos datos se pierden en cada redeploy**.

1. En Railway: **tu servicio → Settings → Volumes → New Volume** (o clic derecho sobre el servicio → Attach Volume).
2. Monta el volumen en **exactamente** esta ruta:

   ```
   /app/data/storage
   ```

> ⚠️ **NO montes el volumen en `/app/data`.** Esa carpeta contiene el código y los assets horneados en la imagen (`serve/app.js`, `web/`, `skills/`, `vendor/`, `models/`, …); un volumen vacío encima los **tapa** y el contenedor arranca con `Error: Cannot find module '/app/data/serve/app.js'`. Por eso los datos escribibles viven en el subdirectorio `storage/`, que sí puede montarse sin ocultar nada.

Con el volumen en `/app/data/storage` persisten la base de datos y los archivos generados entre despliegues. Los assets de solo lectura siguen viniendo de la imagen (se actualizan con cada deploy). Nota: `logs/` y `temp/` no se persisten (son regenerables).

---

## 3. Primer ingreso: cambia el login por defecto

La base de datos se inicializa con un usuario administrador por defecto:

- **Usuario:** `admin`
- **Contraseña:** `admin123`

**Cambia esta contraseña inmediatamente tras el primer inicio de sesión.** Un despliegue público con `admin` / `admin123` es un riesgo de seguridad directo.

---

## 4. API keys de IA (DeepSeek, Anthropic, OpenAI, etc.)

Las claves de los proveedores de IA **NO se configuran como variables de entorno**. Se introducen **dentro del panel web de Toonflow**, en la sección de configuración de proveedores/modelos, una vez que has iniciado sesión.

Esto incluye DeepSeek, Anthropic, OpenAI, Google, xAI, Qwen, Zhipu, MiniMax y demás proveedores soportados. Configúralas desde la interfaz, no en Railway.

---

## 5. Resumen del flujo de despliegue

1. Crea el repositorio en GitHub y haz `git push`.
2. En Railway: **New Project → Deploy from GitHub repo** y selecciona el repo.
3. Añade las variables de entorno (sección 1).
4. Crea y monta el volumen en `/app/data` (sección 2).
5. Espera a que termine el build (`yarn build`) y el deploy.
6. Abre la URL pública, inicia sesión con `admin` / `admin123` y **cambia la contraseña** (sección 3).
7. Configura tus API keys de IA desde el panel web (sección 4).
