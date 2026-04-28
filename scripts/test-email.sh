#!/usr/bin/env bash
# =============================================================================
# Test email: send → wait → check Hermes logs for processing
# =============================================================================
set -euo pipefail

SENDER="test-prueba@ionet.cl"
NOW=$(date '+%Y-%m-%d %H:%M:%S %Z')
SUBJECT="Prueba automática $(date '+%H:%M:%S')"

echo "=== Enviando correo de prueba ==="
echo "From: ${SENDER}"
echo "Subject: ${SUBJECT}"
echo ""

python3 << PYEOF
import os, sys
from pathlib import Path

# Load .env manually (values may contain spaces)
env_path = Path(os.path.expanduser("~/.hermes/.env"))
env_vars = {}
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        env_vars[key.strip()] = val.strip()

addr = env_vars.get("EMAIL_ADDRESS", "")
pwd  = env_vars.get("EMAIL_PASSWORD", "")
imap = env_vars.get("EMAIL_IMAP_HOST", "imap.gmail.com")
smtp = env_vars.get("EMAIL_SMTP_HOST", "smtp.gmail.com")
smtp_port = int(env_vars.get("EMAIL_SMTP_PORT", "587"))

if not addr or not pwd:
    print("ERROR: EMAIL_ADDRESS or EMAIL_PASSWORD not found in .env")
    sys.exit(1)

import smtplib, ssl
from email.mime.text import MIMEText

body = f"""Hola Hermes, esto es una prueba automática del gateway de email.
Por favor responde confirmando que funciona.

Fecha: {os.environ.get('NOW', '')}
"""

msg = MIMEText(body, "plain", "utf-8")
msg["From"] = "${SENDER}"
msg["To"] = addr
msg["Subject"] = "${SUBJECT}"

smtp = smtplib.SMTP(smtp, smtp_port, timeout=30)
smtp.starttls(context=ssl.create_default_context())
smtp.login(addr, pwd)
smtp.send_message(msg)
smtp.quit()
print("Correo enviado OK → " + addr)
PYEOF

echo ""
echo "=== Esperando 25s para que Hermes procese... ==="
sleep 25

echo ""
echo "=== Eventos de Email en logs ==="
docker logs hermes 2>&1 | grep -iE "\[Email\]" | tail -20

echo ""
echo "=== Mensajes nuevos recibidos ==="
docker logs hermes 2>&1 | grep -iE "new message|dispatched|sent reply|send failed" | tail -10
