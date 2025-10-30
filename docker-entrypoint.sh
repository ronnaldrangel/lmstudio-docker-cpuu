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

# Verificar si LM Studio está instalado o intentar descargarlo
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
        echo "This is normal on first run - the binary will be created when LM Studio starts"
    fi
elif [ -f "/data/lms/LM-Studio.AppImage" ]; then
    echo "Found LM Studio AppImage but not extracted. Extracting now..."
    cd /data/lms
    chmod +x LM-Studio.AppImage
    ./LM-Studio.AppImage --appimage-extract
    echo "Extraction complete. Starting LM Studio..."
    /data/lms/squashfs-root/AppRun --no-sandbox &
    sleep 30
else
    echo "LM Studio not found. Attempting to download..."
    cd /data/lms
    
    # Intentar descargar si no existe
    if command -v wget >/dev/null 2>&1; then
        echo "Downloading LM Studio AppImage..."
        DOWNLOAD_URL="https://releases.lmstudio.ai/linux/x86/0.2.29/LM-Studio-0.2.29.AppImage"
        wget -O LM-Studio.AppImage "$DOWNLOAD_URL" && {
            chmod +x LM-Studio.AppImage
            ./LM-Studio.AppImage --appimage-extract
            echo "Download and extraction complete. Starting LM Studio..."
            /data/lms/squashfs-root/AppRun --no-sandbox &
            sleep 30
        } || {
            echo "Download failed. LM Studio will not be available."
            echo "Please check your internet connection or manually provide the AppImage file."
        }
    else
        echo "wget not available. Cannot download LM Studio automatically."
        echo "Please manually provide the LM Studio AppImage file in /data/lms/"
    fi
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
