#!/bin/bash

# Limpiar archivos de bloqueo X11
rm -f /tmp/.X99-lock

# Iniciar servidor X virtual
Xvfb :99 -screen 0 1920x1080x16 &
sleep 2

# Crear directorios necesarios
mkdir -p /root/.cache/lm-studio/.internal
mkdir -p /root/.cache/lm-studio/bin

# Configurar alias para lms si existe
echo 'alias lms="~/.cache/lm-studio/bin/lms"' >> ~/.bashrc

# Verificar si LM Studio está instalado
if [ -f "/data/lms/squashfs-root/AppRun" ]; then
    echo "LM Studio found, starting application..."
    /data/lms/squashfs-root/AppRun --no-sandbox &
    sleep 30
    
    # Verificar si el binario lms existe
    if [ -f "/root/.cache/lm-studio/bin/lms" ]; then
        echo "Starting LM Studio server..."
        /root/.cache/lm-studio/bin/lms server start --cors &
        sleep 5
        
        # Cargar modelo si está especificado
        if [ -n "${MODEL_IDENTIFIER}" ]; then
            echo "Loading model: ${MODEL_IDENTIFIER}"
            /root/.cache/lm-studio/bin/lms load --gpu 0.3 --ttl 3600 --context-length ${CONTEXT_LENGTH:-16384} ${MODEL_IDENTIFIER} &
        fi
    else
        echo "LM Studio binary not found at /root/.cache/lm-studio/bin/lms"
    fi
else
    echo "LM Studio AppImage not found. Please mount or copy LM Studio files to /data/lms/"
fi

# Copiar configuración del servidor HTTP
sleep 5
if [ -f "/http-server-config.json" ]; then
    cp -f /http-server-config.json /root/.cache/lm-studio/.internal/http-server-config.json 2>/dev/null || echo "Could not copy http-server-config.json"
fi

# Iniciar VNC server
echo "Starting VNC server on port 5900..."
x11vnc -display :99 -forever -rfbauth /root/.vnc/passwd -quiet -listen 0.0.0.0 -xkb &

# Mantener el contenedor activo
echo "Container ready. VNC available on port 5900"
echo "If LM Studio is installed, it should be accessible via the GUI"

# Ejecutar bash interactivo
/bin/bash
