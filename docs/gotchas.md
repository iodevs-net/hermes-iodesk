# GOTCHAS — Hermes Agent

Lecciones aprendidas, bugs rastreados, soluciones atómicas.

---

## SOUL.md / System Prompt Staleness

### El system prompt de sesiones existentes NO se regenera al cambiar SOUL.md
**Problema:** Actualizar `SOUL.md` no tiene efecto en las respuestas de Hermes. Sigue respondiendo con la identidad anterior o la identidad genérica.

**Causa raíz (doble capa):**
1. **SQLite:** `run_agent.py:9766-9769` — para sesiones continuadas, carga `system_prompt` desde SQLite en vez de llamar a `_build_system_prompt()`. La primera vez que se toca una sesión, el system prompt se congela en SQLite. Cambios posteriores a SOUL.md son ignorados.
2. **Gateway cache:** `gateway/run.py:709` — `_agent_cache` mantiene instancias `AIAgent` en memoria (con `_cached_system_prompt` poblado). Mientras el cache tenga la instancia vieja, ni siquiera llega a la lógica de SQLite.

**Fix permanente (implementado):**
- `agent/prompt_builder.py:994` — nueva función `get_soul_mtime()` que retorna timestamp de modificación de SOUL.md
- `run_agent.py:9756-9769` — antes de usar cached/stored system prompt, compara mtime de SOUL.md contra session `started_at`. Si SOUL.md es más nuevo, invalida el cache y fuerza rebuild
- Funciona para ambos casos: gateway cache hit y AIAgent nuevo con stored_prompt en DB

**Fix manual (antes del parche):**
```bash
# 1. Eliminar system_prompt de SQLite
docker exec hermes python3 -c "
import sqlite3
db = sqlite3.connect('/opt/data/state.db')
db.execute('UPDATE sessions SET system_prompt=NULL WHERE id=\"SESSION_ID\"')
db.commit()
"
# 2. Limpiar cache gateway
docker restart hermes
# 3. Eliminar session files
docker exec hermes rm -f /opt/data/sessions/SESSION_ID.jsonl
```

### Gateway cache usa config_signature que no incluye SOUL.md
**Problema:** `gateway/run.py:10160` compara `cached[1] == _sig` donde `_sig` es un hash de configuración (model, tools, etc.). SOUL.md no afecta el signature, por lo que cambios en SOUL.md no producen cache miss.

**Estado:** No aplica directamente con el fix de `run_agent.py` porque la invalidación ocurre dentro de `run_conversation()`, pero es bueno saberlo para futuros diagnósticos.

---

## Email Platform

### SMTP de Gmail reescribe From header
**Problema:** Enviar email vía `smtp.gmail.com` con From: `ventas@ionet.cl` → Gmail reescribe a `ionet.ventas@gmail.com` (el usuario autenticado).

**Headers crudos de Gmail SMTP:**
```
From: ionet.ventas@gmail.com
X-Google-Original-From: ventas@ionet.cl
```

**Impacto:** El gateway salta el email como "self-message" en `email.py:412` (`sender_addr == self._address.lower()`).

**Workaround:** Inyectar email directo vía IMAP APPEND con From: correcto. O usar SMTP externo (no Gmail) para enviar a hermes@iodevs.net.

### IMAP APPEND siempre marca como \Seen en Gmail
**Problema:** `imap.uid("append", "INBOX", ...)` + `imap.uid("store", uid, "-FLAGS", "(\\Seen)")` — Gmail ignora el store y el mensaje queda como SEEN.

**Causa:** Gmail no permite remover el flag \Seen vía IMAP STORE. Es una limitación del proveedor.

**Fix:** No hay. Los mensajes injectados vía APPEND siempre quedan como SEEN. Para testing, usar SMTP a hermes@iodevs.net (llega como UNSEEN a Gmail inbox) o agregar whitelist temporal.

### Email de "self" se salta en dispatch
**Problema:** `email.py:412` — si `sender_addr == self._address.lower()`, el email se descarta. Esto ocurre al enviar desde `ionet.ventas@gmail.com` (el mismo address configurado como EMAIL_ADDRESS).

**Solución:** Para debug/testing, agregar `ionet.ventas@gmail.com` a `EMAIL_ALLOWED_USERS` NO es suficiente — el check de "self-message" ocurre ANTES de la autorización. Hay que modificar el sender o usar From diferente (IMAP APPEND).

### EMAIL_ALLOWED_USERS requiere match exacto
**Problema:** `_is_user_authorized()` en `gateway/run.py:3179` usa intersección exacta de set. No soporta wildcards ni dominios.

**Fix:** No cambiar, es deliberado por seguridad. Listar emails explícitamente.

---

## Container / Infra

### Restart loop: "Shutdown diagnostic — other hermes processes running"
**Problema:** Gateway recibe SIGTERM porque detecta otro proceso hermes corriendo. Causa restart loop de ~5-15 segundos.

**Causa:** `tini` (PID 1) ejecuta el entrypoint que arranca el gateway concurrentemente con otros procesos. El entrypoint tiene un watchdog que detecta procesos hermes adicionales y envía SIGTERM.

**Impacto:** Durante el restart loop, emails entrantes son cargados en `_seen_uids` y nunca procesados.

**Workaround:** Esperar a que el container se estabilice (~2-3 ciclos). El restart loop es autolimitante.

### Code changes no persisten en container
**Problema:** Modificar `run_agent.py` o `agent/prompt_builder.py` en el repo host no actualiza el container. El código está baked en la imagen Docker (no bind mount).

**Deploy rápido (dev):**
```bash
docker cp run_agent.py hermes:/opt/hermes/run_agent.py
docker cp agent/prompt_builder.py hermes:/opt/hermes/agent/prompt_builder.py
docker restart hermes
```

**Deploy permanente (prod):**
```bash
cd /path/to/hermes-iodesk
docker build -t hermes:latest .
# Actualizar imagen en docker-compose.yml y recrear container
```

---

## Sessión Recovery

### Context compression recrea session files problemáticos
**Problema:** Después de eliminar session files `.jsonl` y `.json` de `/opt/data/sessions/`, context compression puede recrearlos si la sesión sigue en SQLite.

**Fix:** Siempre eliminar de SQLite PRIMERO, después los archivos. O mejor, solo limpiar SQLite (el campo `system_prompt`), que es lo que realmente importa.
