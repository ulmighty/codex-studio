# Vault Integration Patterns

## Bidirectional Flow

### INTO Applications
- Vault Agent sidecar pattern
- Template rendering for configs
- Environment variable injection
- File-based secret delivery

### FROM Applications
- API key harvesting
- Service URL registration
- Health status updates
- Metric collection

## AppRole Authentication
- One AppRole per application
- Least-privilege policies
- Auto-renewal of tokens
- Wrapped secret IDs

## Secret Paths
```
secret/
├── global/           # Shared secrets
├── <app>/           # App-specific secrets
│   ├── api_key      # Generated API key
│   ├── url          # Service URL
│   └── config/      # Configuration values
└── integration/     # Inter-app connections
```
