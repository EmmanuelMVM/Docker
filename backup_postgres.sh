#!/bin/bash

# ==========================
# CONFIGURACIÓN
# ==========================

CONTAINER_NAME="mysql_db"          # Nombre del contenedor Docker
DB_USER="usuario"
DB_NAME="caremind_db"

BACKUP_DIR="/var/backups/postgres"
LOG_FILE="/var/log/postgres_backup.log"

REMOTE_USER="backupuser"
REMOTE_HOST="192.168.x.x"
REMOTE_DIR="/home/backupuser/postgres_backups"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="backup_${DB_NAME}_${DATE}.sql"
COMPRESSED_FILE="${BACKUP_FILE}.gz"

RETENTION_DAYS=7

# ==========================
# CREACIÓN DE DIRECTORIOS
# ==========================

mkdir -p "$BACKUP_DIR"

# ==========================
# INICIO DEL BACKUP
# ==========================

echo "[$(date)] Iniciando copia de seguridad..." >> "$LOG_FILE"

# Dump de la base de datos desde Docker
docker exec -t $CONTAINER_NAME pg_dump -U $DB_USER $DB_NAME > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -ne 0 ]; then
    echo "[$(date)] ERROR en pg_dump" >> "$LOG_FILE"
    exit 1
fi

# Comprimir
gzip "$BACKUP_DIR/$BACKUP_FILE"

# Enviar al servidor remoto
scp "$BACKUP_DIR/$COMPRESSED_FILE" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}

if [ $? -ne 0 ]; then
    echo "[$(date)] ERROR al enviar al servidor remoto" >> "$LOG_FILE"
    exit 1
fi

# Borrar backups antiguos
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -name "*.gz" -delete

echo "[$(date)] Backup completado correctamente" >> "$LOG_FILE"
echo "--------------------------------------" >> "$LOG_FILE"

exit 0
