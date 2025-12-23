#!/bin/bash
# ============================================
# Script Avanzado de Auditoría y Hardening de Sistemas Linux
# Autor: Pablo Dengra
# Fecha: $(date +"%Y-%m-%d")
# ============================================

# ============================
# Variables
# ============================
INFORME="$HOME/auditoria_seguridad_completa_$(date +%Y%m%d).log"
EMAIL="admin@tuservidor.com"
TELEGRAM_BOT_TOKEN="AQUI_TU_TOKEN"
TELEGRAM_CHAT_ID="AQUI_TU_CHAT_ID"

# ============================
# Cabecera
# ============================
{
echo "============================================"
echo " AUDITORÍA DE SEGURIDAD COMPLETA - $(date)"
echo " Host: $(hostname)"
echo "============================================"
} > "$INFORME"

# ============================
# 1. Información del sistema
# ============================
echo -e "\n[+] Sistema operativo:" >> "$INFORME"
uname -a >> "$INFORME"
cat /etc/os-release >> "$INFORME"

# ============================
# 2. Usuarios conectados
# ============================
echo -e "\n[+] Usuarios conectados:" >> "$INFORME"
who >> "$INFORME"

# ============================
# 3. Intentos fallidos de login
# ============================
echo -e "\n[+] Últimos intentos de login fallidos:" >> "$INFORME"
lastb -n 10 2>/dev/null >> "$INFORME"

# ============================
# 4. Usuarios con sudo
# ============================
echo -e "\n[+] Usuarios con privilegios sudo:" >> "$INFORME"
getent group sudo | cut -d: -f4 >> "$INFORME"

# ============================
# 5. Usuarios con acceso al sistema
# ============================
echo -e "\n[+] Usuarios con shell válida:" >> "$INFORME"
awk -F: '$7 !~ /nologin|false/ {print $1}' /etc/passwd >> "$INFORME"

# ============================
# 6. Procesos activos
# ============================
echo -e "\n[+] Procesos TOP por CPU:" >> "$INFORME"
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -n 6 >> "$INFORME"

# ============================
# 7. Puertos abiertos
# ============================
echo -e "\n[+] Puertos y servicios abiertos:" >> "$INFORME"
ss -tulnp >> "$INFORME"

# ============================
# 8. Servicios activos al arranque
# ============================
echo -e "\n[+] Servicios habilitados al arranque:" >> "$INFORME"
systemctl list-unit-files --type=service | grep enabled >> "$INFORME"

# ============================
# 9. Firewall
# ============================
echo -e "\n[+] Estado del firewall (ufw):" >> "$INFORME"
if command -v ufw &>/dev/null; then
    ufw status verbose >> "$INFORME"
else
    echo "UFW no instalado" >> "$INFORME"
fi

# ============================
# 10. Configuración SSH
# ============================
echo -e "\n[+] Configuración SSH relevante:" >> "$INFORME"
grep -E "PermitRootLogin|PasswordAuthentication|Port" /etc/ssh/sshd_config 2>/dev/null >> "$INFORME"

# ============================
# 11. Archivos SUID
# ============================
echo -e "\n[+] Archivos con permisos SUID:" >> "$INFORME"
find / -perm -4000 -type f 2>/dev/null | head -n 10 >> "$INFORME"

# ============================
# 12. Cron jobs
# ============================
echo -e "\n[+] Tareas programadas (cron):" >> "$INFORME"
ls -l /etc/cron.* >> "$INFORME"

# ============================
# 13. Cambios recientes en /etc
# ============================
echo -e "\n[+] Archivos modificados en /etc (7 días):" >> "$INFORME"
find /etc -type f -mtime -7 2>/dev/null >> "$INFORME"

# ============================
# 14. Uso de disco
# ============================
echo -e "\n[+] Uso de disco:" >> "$INFORME"
df -h >> "$INFORME"

# ============================
# 15. Módulos del kernel
# ============================
echo -e "\n[+] Módulos del kernel cargados:" >> "$INFORME"
lsmod >> "$INFORME"

# ============================
# 16. Actualizaciones
# ============================
echo -e "\n[+] Actualizaciones disponibles:" >> "$INFORME"
apt list --upgradable 2>/dev/null | grep -v "Listing" >> "$INFORME"

# ============================
# Final
# ============================
echo -e "\n============================================" >> "$INFORME"
echo " Auditoría finalizada correctamente" >> "$INFORME"
echo " Informe generado en: $INFORME" >> "$INFORME"
echo "============================================" >> "$INFORME"

# ============================
# Envío por email
# ============================
if command -v msmtp &>/dev/null; then
    {
        echo "Subject: Informe Auditoría de Seguridad - $(hostname)"
        echo "To: $EMAIL"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo
        cat "$INFORME"
    } | msmtp "$EMAIL"
fi

# ============================
# Envío por Telegram
# ============================
if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
        -F chat_id="$TELEGRAM_CHAT_ID" \
        -F document=@"$INFORME" \
        -F caption="Informe de Auditoría de Seguridad - $(hostname)"
fi

