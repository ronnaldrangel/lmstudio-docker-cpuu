
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

# Copiar y procesar archivos de LM Studio
RUN <<eot
    set -eux
    
    # Intentar copiar archivos LM-Studio si existen en el contexto de build
    if ls ./LM-Studio* 1> /dev/null 2>&1; then
        echo "Found LM-Studio files, copying..."
        cp ./LM-Studio* /data/lms/ 2>/dev/null || echo "Could not copy some LM-Studio files"
    else
        echo "No LM-Studio files found in build context"
    fi
    
    # Verificar si existen archivos AppImage en el destino
    if ls /data/lms/*.AppImage 1> /dev/null 2>&1; then
        echo "Found AppImage files, processing..."
        chmod ugo+x /data/lms/*.AppImage
        cd /data/lms
        for appimage in *.AppImage; do
            if [ -f "$appimage" ]; then
                echo "Extracting $appimage"
                ./"$appimage" --appimage-extract
            fi
        done
    else
        echo "No AppImage files found, creating placeholder structure..."
        mkdir -p /data/lms/squashfs-root
        echo "#!/bin/bash" > /data/lms/squashfs-root/AppRun
        echo "echo 'LM Studio not installed - please mount or copy AppImage files'" >> /data/lms/squashfs-root/AppRun
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
