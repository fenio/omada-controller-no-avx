# Omada Controller (No AVX)

TP-Link Omada Controller Docker image for CPUs **without AVX support**.

## The Problem

The official Omada Controller v6.x Docker images (including [mbentley/omada-controller](https://github.com/mbentley/docker-omada-controller)) ship with MongoDB binaries that require AVX CPU instructions. Many CPUs lack AVX support, including:

- Intel Atom processors (many models through 2020+)
- Low-power Intel Celeron/Pentium (Atom-based)
- AMD Bobcat/Jaguar-based APUs
- Older Intel CPUs (pre-Sandy Bridge)
- Older AMD CPUs (pre-Bulldozer)

These CPUs cannot run standard MongoDB binaries and therefore cannot run standard Omada Controller v6.x images.

## The Solution

This image bundles:
- **Omada Controller 6.0.0.25** - The latest TP-Link Omada Controller
- **MongoDB 7.0.28 (No AVX)** - MongoDB compiled from source without AVX requirements from [fenio/mongodb-no-avx](https://github.com/fenio/mongodb-no-avx)

## Usage

### Docker Run

```bash
docker run -d \
  --name omada-controller \
  --restart unless-stopped \
  -p 8088:8088 \
  -p 8043:8043 \
  -p 8843:8843 \
  -p 27001:27001/udp \
  -p 29810:29810/udp \
  -p 29811-29817:29811-29817 \
  -v omada-data:/data \
  ghcr.io/fenio/omada-controller-no-avx:latest
```

### Docker Compose

```yaml
services:
  omada-controller:
    image: ghcr.io/fenio/omada-controller-no-avx:latest
    container_name: omada-controller
    restart: unless-stopped
    ports:
      - "8088:8088"
      - "8043:8043"
      - "8843:8843"
      - "27001:27001/udp"
      - "29810:29810/udp"
      - "29811-29817:29811-29817"
    volumes:
      - omada-data:/data

volumes:
  omada-data:
```

### Home Assistant Add-on

This image is designed to work with the [Home Assistant Omada Controller Add-on](https://github.com/fenio/ha-addons).

Add this repository to your Home Assistant add-on store:
```
https://github.com/fenio/ha-addons
```

## Available Tags

- `latest`, `6`, `6.0`, `6.0.0.25` - Omada Controller 6.0.0.25 with MongoDB 7.0.28

## Architecture

- `linux/amd64` only (ARM not supported - ARM CPUs typically don't have AVX issues)

## Credits

- [mbentley/docker-omada-controller](https://github.com/mbentley/docker-omada-controller) - Original Omada Controller Docker image
- [jkunczik/home-assistant-omada](https://github.com/jkunczik/home-assistant-omada) - Home Assistant add-on for Omada Controller
- [fenio/mongodb-no-avx](https://github.com/fenio/mongodb-no-avx) - MongoDB compiled without AVX requirements

## License

This project follows the licenses of the upstream projects it's based on.
