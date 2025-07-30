# Base Image Strategy

## Selected Base Images

1. **debian:bullseye-slim** (18 apps)
   - Stable, well-tested base
   - Excellent package availability
   - Python, .NET, Node.js support
   - Size: ~80MB base

2. **alpine:latest** (8 apps) 
   - Minimal attack surface
   - Size: ~5MB base
   - Perfect for Go binaries
   - musl libc (watch for compatibility)

3. **nvidia/cuda:12.3.1-runtime-ubuntu22.04** (3 apps)
   - GPU acceleration support
   - CUDA 12.3.1 for latest GPUs
   - Ubuntu 22.04 LTS base
   - Size: ~2GB (includes CUDA)

4. **php:8.3-fpm-alpine** (4 apps)
   - Latest PHP 8.3
   - FPM for performance
   - Alpine for minimal size
   - Size: ~30MB base

## Security Hardening

- Non-root user (uid:99, gid:100 for Unraid)
- Minimal packages installed
- No package manager in final stage
- Read-only root filesystem where possible
- Dropped capabilities
- Security scanning with Trivy
