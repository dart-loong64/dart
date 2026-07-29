FROM ghcr.io/loong64/debian:trixie-slim

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        git \
        libasan8 \
        libatomic1 \
        libgcc-s1 \
        liblsan0 \
        libtsan2 \
        openssh-client \
        unzip \
    ; \
    rm -rf /var/lib/apt/lists/*

# Create a minimal runtime environment for executing AOT-compiled Dart code
# with the smallest possible image size.
# usage: COPY --from=dart:xxx /runtime/ /
# uses hard links here to save space
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) \
            TRIPLET="x86_64-linux-gnu" ; \
            FILES="/lib64/ld-linux-x86-64.so.2" ;; \
        armhf) \
            TRIPLET="arm-linux-gnueabihf" ; \
            FILES="/lib/ld-linux-armhf.so.3 \
                /lib/arm-linux-gnueabihf/ld-linux-armhf.so.3";; \
        arm64) \
            TRIPLET="aarch64-linux-gnu" ; \
            FILES="/lib/ld-linux-aarch64.so.1 \
                /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1" ;; \
        loong64) \
            TRIPLET="loongarch64-linux-gnu" ; \
            FILES="/lib64/ld-linux-loongarch-lp64d.so.1 \
                /lib/loongarch64-linux-gnu/ld-linux-loongarch-lp64d.so.1" ;; \
        riscv64) \
            TRIPLET="riscv64-linux-gnu" ; \
            FILES="/lib/ld-linux-riscv64-lp64d.so.1 \
                /lib/riscv64-linux-gnu/ld-linux-riscv64-lp64d.so.1" ;; \
        *) \
            echo "Unsupported architecture" ; \
            exit 5;; \
    esac; \
    FILES="$FILES \
        /etc/nsswitch.conf \
        /etc/ssl/certs \
        /usr/share/ca-certificates \
        /lib/$TRIPLET/libc.so.6 \
        /lib/$TRIPLET/libdl.so.2 \
        /lib/$TRIPLET/libm.so.6 \
        /lib/$TRIPLET/libnss_dns.so.2 \
        /lib/$TRIPLET/libpthread.so.0 \
        /lib/$TRIPLET/libresolv.so.2 \
        /lib/$TRIPLET/librt.so.1"; \
    for f in $FILES; do \
        dir=$(dirname "$f"); \
        mkdir -p "/runtime$dir"; \
        cp --archive --link --dereference --no-target-directory "$f" "/runtime$f"; \
    done

ENV DART_SDK /usr/lib/dart
ENV PATH $DART_SDK/bin:/root/.pub-cache/bin:$PATH

WORKDIR /root
RUN --mount=type=bind,source=.,target=/build \
    set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) \
            SDK_ARCH="x64";; \
        armhf) \
            SDK_ARCH="arm";; \
        arm64) \
            SDK_ARCH="arm64";; \
        loong64) \
            SDK_ARCH="loong64";; \
        riscv64) \
            SDK_ARCH="riscv64";; \
    esac; \
    tar -xzf /build/dartsdk-linux-$SDK_ARCH-release.tar.gz; \
    mv dart-sdk "$DART_SDK" && chmod 755 "$DART_SDK" && chmod 755 "$DART_SDK/bin";
