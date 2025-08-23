# Nebula DOM Cartographer

Nebula DOM Cartographer is a toolkit for GPU‑accelerated DOM analysis and
AI‑assisted selector generation.  It is packaged as a Chrome extension and comes
with utilities for benchmarking, testing and development.

## Features

- WebGPU/WebGL powered DOM parsing for high‑performance analysis of large pages
- AI‑assisted CSS selector generation for resilient element targeting
- Benchmarks, unit tests and end‑to‑end tests included

## Prerequisites

- [Node.js](https://nodejs.org/) 18 or later
- `npm` (comes with Node.js)

## Installation

On Unix‑like systems:

```bash
./scripts/install.sh
```

On Windows (PowerShell):

```powershell
scripts\install.ps1
```

These scripts install dependencies and build the extension into the `dist/`
directory.

## Usage

To build and test manually:

```bash
npm install
npm run build
npm test
```

Load the `dist` directory as an unpacked extension in Chrome.

## Development

- `npm run lint` – run ESLint over the codebase
- `npm run e2e` – execute Playwright end‑to‑end tests
- `npm run bench` – run performance benchmarks

## Testing

Run the full test suite with:

```bash
npm test
```

## Benchmarking

CPU scaling benchmarks can be executed with:

```bash
npm run bench
```

