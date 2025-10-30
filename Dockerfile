
# Usar imagen base Ubuntu estándar para CPU (sin CUDA/GPU)
ARG baseimage=ubuntu:24.04

FROM ${baseimage} AS baseimage
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TZ=Etc/UTC

ARG DEBIAN_FRONTEND=noninteractive
# Build arguments
ARG ARG_UID=1000
ARG ARG_GID=1000

RUN <<eot
    set -eux
    apt -qy update
    apt -qy install --no-install-recommends \
        -o APT::Install-Recommends=false \
        -o APT::Install-Suggests=false \
        console-setup tzdata dbus x11-utils x11-xserver-utils
    apt -qy update
    DEBIAN_FRONTEND=noninteractive  apt -qy install --no-install-recommends \
        -o APT::Install-Recommends=false \
        -o APT::Install-Suggests=false \
        libfuse2 kmod fuse libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libgtk-3-0 libgbm1 libasound2t64 xserver-xorg xvfb x11vnc
    mkdir -p /root/.vnc && x11vnc -storepasswd test123 /root/.vnc/passwd
eot

ENV DISPLAY=:99

#########################

FROM baseimage AS final

# Crear directorio para LM Studio y copiar archivos de configuración
RUN mkdir -p /data/lms /root/.cache/lm-studio/.internal /root/.cache/lm-studio/bin
COPY ./http-server-config.json /http-server-config.json

# Instalar curl y wget para descargar LM Studio
RUN apt-get update && apt-get install -y curl wget && rm -rf /var/lib/apt/lists/*

# Descargar y procesar LM Studio automáticamente
RUN <<eot
    set -eux
    
    # Descargar LM Studio AppImage desde GitHub releases
    echo "Downloading LM Studio AppImage..."
    cd /data/lms
    
    # Obtener la URL de descarga más reciente
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/lmstudio-ai/lmstudio.js/releases/latest | grep "browser_download_url.*AppImage" | cut -d '"' -f 4 | head -1)
    
    # Si no se encuentra en lmstudio.js, intentar con el repositorio principal
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "Trying alternative download method..."
        # URL directa conocida (puede necesitar actualización)
        DOWNLOAD_URL="https://releases.lmstudio.ai/linux/x86/0.2.29/LM-Studio-0.2.29.AppImage"
    fi
    
    if [ -n "$DOWNLOAD_URL" ]; then
        echo "Downloading from: $DOWNLOAD_URL"
        wget -O LM-Studio.AppImage "$DOWNLOAD_URL" || {
            echo "Download failed, creating placeholder..."
            mkdir -p /data/lms/squashfs-root
            echo "#!/bin/bash" > /data/lms/squashfs-root/AppRun
            echo "echo 'LM Studio download failed - please check internet connection'" >> /data/lms/squashfs-root/AppRun
            chmod +x /data/lms/squashfs-root/AppRun
            exit 0
        }
        
        # Hacer ejecutable y extraer
        chmod +x LM-Studio.AppImage
        echo "Extracting LM Studio AppImage..."
        ./LM-Studio.AppImage --appimage-extract
        
        echo "LM Studio successfully downloaded and extracted"
    else
        echo "Could not find download URL, creating placeholder..."
        mkdir -p /data/lms/squashfs-root
        echo "#!/bin/bash" > /data/lms/squashfs-root/AppRun
        echo "echo 'LM Studio download URL not found'" >> /data/lms/squashfs-root/AppRun
        chmod +x /data/lms/squashfs-root/AppRun
    fi
eot


ADD ./docker-entrypoint.sh /usr/local/bin/
ADD ./docker-healthcheck.sh /usr/local/bin/

# Ensure the scripts are executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-healthcheck.sh
# Setup the healthcheck
HEALTHCHECK --interval=1m --timeout=10s --start-period=1m \
  CMD /bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1


# Run the server
# CMD ["sh", "-c", "tail -f /dev/null"] # For development: keep container open
ENTRYPOINT ["/bin/bash", "/usr/local/bin/docker-entrypoint.sh"]
