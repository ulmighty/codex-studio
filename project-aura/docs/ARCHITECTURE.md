# Architecture Overview

Project Aura uses a provider/strategy pattern. Interfaces live under
`aura/providers/<category>/base.py` and concrete implementations are selected at
runtime via `config.yaml`. The `FusionEngine` combines voice, hand and gaze
inputs into high level intents which are dispatched on the `CommandBus`.

The application entry point is `aura/app.py` which wires together providers
based on configuration.
