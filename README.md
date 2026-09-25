# Microsoft Agent Framework with Azure Container Apps Custom Container Sessions

This project demonstrates how to use **Azure Container Apps dynamic sessions with custom containers** to create an AI-powered agent using **Microsoft Agent Framework** (successor to AutoGen) that can execute Python code securely with pre-installed data science libraries.

## Overview

The application is a Flask-based web interface that leverages **Microsoft Agent Framework** for AI orchestration and **Azure Container Apps dynamic sessions with custom containers** for secure Python code execution. When users request calculations or Python code execution, the agent automatically executes code in isolated containers pre-configured with numpy, pandas, and matplotlib.

## Architecture

```
                    ┌─────────────────────────┐
                    │    User/Client          │
                    └───────────┬─────────────┘
                                │ HTTPS
                                ▼
            ┌───────────────────────────────────────┐
            │  Azure Container App                  │
            │  (Agent Framework)                    │
            │  ┌─────────────────────────────────┐  │
            │  │ Flask API + Agent Framework     │  │
            │  │ - Chat interface                │  │
            │  │ - Tool selection & orchestration│  │
            │  └─────────────────────────────────┘  │
            └───────┬──────────────────┬────────────┘
                    │                  │
        Managed     │                  │ Managed
        Identity    │                  │ Identity
                    ▼                  ▼
    ┌──────────────────────┐  ┌─────────────────────────────┐
    │  Azure OpenAI        │  │  Dynamic Session Pool       │
    │  - GPT-4o-mini       │  │  (Custom Containers)        │
    │  - Agent LLM         │  │                             │
    └──────────────────────┘  │  ┌───────────────────────┐  │
                              │  │ Session Container     │  │
                              │  │ - Python 3.11         │  │
                              │  │ - numpy, pandas       │  │
                              │  │ - matplotlib          │  │
                              │  │ - Isolated execution  │  │
                              │  └───────────────────────┘  │
                              └─────────────────────────────┘
                                          │ Pulls from
                                          ▼
                              ┌──────────────────────────────┐
                              │  Azure Container Registry    │
                              │  - Executor container image  │
                              └──────────────────────────────┘
```

## Features

- **Custom Container Sessions**: Primary feature using Azure Container Apps dynamic sessions with custom Docker containers for secure Python code execution
- **Pre-installed Libraries**: Custom container includes numpy, pandas, matplotlib, and data file format support (openpyxl, xlrd, pyarrow, lxml)
- **Microsoft Agent Framework**: Next-generation AI orchestration with intelligent tool selection
- **Azure OpenAI Integration**: GPT-4o-mini model with managed identity authentication
- **Interactive Web UI**: Modern chat interface with code execution visualization
- **Secure Isolated Execution**: Each code execution runs in a separate, secure Hyper-V isolated container
- **Session Management**: Automatic lifecycle tracking with visual session status indicators
- **Per-client Isolation**: Opaque, server-generated cookies keep conversation and execution state separate across clients

## Prerequisites

- Python 3.10 or later
- Azure subscription with access to:
  - **Azure Container Apps** (for custom container session pools)
  - **Azure OpenAI Service** (for AI agent capabilities)
  - **Azure Container Registry** (for storing custom container images)
- Azure CLI installed and configured
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) installed
- Docker (for local development)

## Quick Start with Azure Developer CLI (azd)

The easiest way to deploy this application is using the Azure Developer CLI (azd):

### 1. Deploy to Azure

```bash
# Clone the repository
git clone <your-repo-url>
cd dynamic-sessions-custom-container

# Login to Azure
azd auth login

# Step 1: Provision infrastructure and build session container image
azd provision

# Step 2: Create session pool and deploy application
azd up
```

The deployment requires two steps because custom container sessions need the image to exist in ACR before the session pool can be created:

1. **`azd provision`**: Creates Azure Container Registry, OpenAI, and Container Apps Environment. The `postprovision` hook automatically builds and pushes the session executor image to ACR.
2. **`azd up`**: Creates the Session Pool (image now exists) and deploys the Agent Framework application.

> **Note**: This sample uses **custom container sessions** (not the built-in `PythonLTS` container type). The built-in Python sessions work with a single `azd up`, but custom containers require this two-step approach.

> **Local run access**: During `azd provision`, the template automatically grants the signed-in user the **Cognitive Services OpenAI User** role on the Azure OpenAI resource and the **Azure Container Apps Session Executor** role on the session pool so local runs (using Azure CLI auth) work without extra manual steps.

### 2. Access Your Application

After deployment, azd will provide you with:
- **Application URL**: Access your chat interface at the deployed URL
- **Pre-installed Libraries**: Custom container includes numpy, pandas, matplotlib, and data file format libraries
- **Environment Details**: See resource details with `azd show`

### 3. Manage Your Deployment

```bash
# View deployment status and URLs
azd show

# Redeploy after code changes
azd deploy

# Clean up resources
azd down
```

## Local Development

### 1. Setup Environment

```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Linux/macOS:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Environment Variables

For local runs, you can load the azd environment values (recommended) or set them manually.

```bash
# Windows (PowerShell)
./scripts/load-env.ps1

# Linux/macOS
source ./scripts/load-env.sh
```

If you prefer manual configuration, set:

- `AZURE_OPENAI_ENDPOINT`
- `AZURE_OPENAI_CHAT_DEPLOYMENT_NAME` (or `AZURE_OPENAI_DEPLOYMENT`)
- `AZURE_CONTAINER_APPS_SESSION_POOL_ENDPOINT`
- `SESSION_POOL_AUDIENCE` (defaults to `https://dynamicsessions.io/.default`)
- `SESSION_COOKIE_SECURE` (defaults to `false` locally; the Bicep deployment sets it to `true`)
- `SESSION_COOKIE_MAX_AGE_SECONDS` (defaults to 30 minutes)
- `MAX_CONVERSATION_THREADS` (defaults to 100)
- `SESSION_SIGNING_KEY` (optional; generated at process startup when omitted)

### 3. Run Locally

```bash
# Ensure Azure CLI auth includes OpenAI scope (first time only)
az login --scope https://cognitiveservices.azure.com/.default

python main.py
```

Access the application at:

- **Chat Interface**: <http://localhost:8080>
- **API Documentation**: <http://localhost:8080/docs/>
- **Health Check**: <http://localhost:8080/health>

## How Custom Container Sessions Work

This application showcases **Azure Container Apps dynamic sessions with custom containers**:

1. **Custom Container Build**: The `session-container/Dockerfile` defines a Python environment with pre-installed libraries
2. **Container Registration**: azd hooks automatically build and push the container to Azure Container Registry
3. **Session Pool Configuration**: The session pool is configured to use the custom container image
4. **Code Execution**: When the agent needs to run Python code, it requests a session from the pool
5. **Isolated Execution**: Code runs in a secure, pre-configured container with all required libraries
6. **State Persistence**: Variables persist within the same session for follow-up calculations
7. **Resource Management**: Sessions automatically scale based on demand and timeout after inactivity

### Example Interaction Flow

```text
User: "Calculate the factorial of 10"
Agent: Detects need for code execution → Calls execute_in_dynamic_session tool
Session Pool: Allocates custom container → Runs Python code → Returns result
Agent: Formats and displays: "Factorial of 10 is 3,628,800"

User: "Now find the square root of that number"
Agent: Uses same session → Executes code → Returns result (maintains state)
Session Pool: Returns "1,904.93..." (remembers previous calculation)
```

## API Usage

### Chat Endpoint

**POST** `/chat`

```json
{
  "prompt": "Calculate the mean of [1, 2, 3, 4, 5]"
}
```

The server creates an opaque `HttpOnly` session cookie. API clients must retain the cookie between requests to preserve conversation and code-execution state.

Response:

```json
{
  "response": "I've calculated that for you.",
  "agent": "Microsoft Agent Framework SmartAssistant",
  "model": "gpt-4o-mini",
  "tools_used": [
    {
      "name": "execute_in_dynamic_session",
      "icon": "📦",
      "description": "Python Execution"
    }
  ]
}
```

For example, with curl:

```bash
curl -c cookies.txt -b cookies.txt \
  -X POST http://localhost:8080/api/chat/ \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Calculate the mean of [1, 2, 3, 4, 5]"}'

curl -c cookies.txt -b cookies.txt \
  -X DELETE http://localhost:8080/api/chat/session
```

### Interactive Web Interface

The web interface demonstrates custom container sessions:

- **Automatic Code Execution**: Math and calculation questions trigger Python code execution in custom containers
- **Pre-installed Libraries**: Access numpy, pandas, matplotlib, and more without installation
- **Private Session Tracking**: Conversation and execution state is scoped to the caller's opaque cookie
- **Code Visualization**: See the Python code that was executed and its output
- **Session Persistence**: Follow-up questions maintain context within the same session

## Key Components

### Azure Container Apps Custom Container Sessions

- **Primary feature**: Secure, isolated Python execution with pre-installed libraries
- **Custom container**: Python 3.11 with numpy, pandas, matplotlib, requests, flask, and data processing libraries
- **Dynamic scaling**: Sessions are created and destroyed based on demand
- **Pre-configured environment**: No need to install packages during execution
- **Security**: Hyper-V isolation between different user sessions

### Microsoft Agent Framework

- **Successor to AutoGen**: Next-generation AI orchestration framework
- **Intelligent tool selection**: Automatically chooses the right tool based on user intent
- **Type-safe functions**: `@ai_function` decorator for automatic schema generation
- **Session management**: Maintains conversation state across multiple interactions

### Azure OpenAI Integration

- **GPT-4o-mini model**: Fast and efficient for agent orchestration and code generation
- **Managed identity**: Keyless authentication for secure service-to-service communication
- **Automatic code detection**: Identifies when Python execution is needed for math/calculations

### Authentication & Security

- **Managed Identity**: User-assigned managed identity for all Azure service communication
- **No credentials in code**: Uses Azure DefaultAzureCredential
- **Role-based access**: Proper RBAC configuration for OpenAI and session pool access
- **Container isolation**: Hyper-V isolation for secure code execution
- **Server-controlled sessions**: Clients cannot choose conversation or Dynamic Session identifiers
- **Same-origin browser access**: The template does not enable wildcard CORS

> **Security scope:** The deployed sample is intentionally anonymous to preserve a simple gallery experience. The opaque cookie prevents cross-client state sharing, but it is not user authentication. Before using this sample with sensitive data or exposing it for production use, enable Azure Container Apps authentication and authorization, restrict ingress, and apply resource-usage controls.

The sample uses one application replica because conversation threads are intentionally held in memory for simplicity. Cookies are cryptographically signed, threads expire after inactivity, and the in-memory collection is bounded. Production deployments that require scaling or durable conversations should move thread state to a shared store with TTL support.

## Project Structure

```
├── main.py                      # Agent Framework application with Flask UI
├── Dockerfile                   # Main application container
├── requirements.txt             # Python dependencies for main app
├── session-container/
│   ├── Dockerfile              # Custom session executor container
│   └── server.py               # Session execution server
├── infra/
│   └── main.bicep              # Azure infrastructure as code
├── azure.yaml                   # azd configuration with hooks
├── docs/
│   ├── MANAGED-IDENTITY.md     # Keyless authentication guide
│   ├── OBSERVABILITY.md        # Monitoring and tracing setup
│   └── VNET-INTEGRATION.md     # Private networking configuration
└── README.md
```

## Configuration

### Azure YAML Hooks

The `azure.yaml` includes hooks that handle the two-phase deployment for custom containers:

- **`preprovision`**: Checks if the session container image exists; sets `SKIP_SESSION_POOL` accordingly
- **`postprovision`**: Builds and pushes the custom session container to ACR, marks image as pushed

```yaml
hooks:
  preprovision:
    run: |
      # Skip session pool on first run (image doesn't exist yet)
      if SESSION_IMAGE_PUSHED != "true": SKIP_SESSION_POOL = true
  postprovision:
    run: |
      az acr build --registry <acr-name> --image dynamic-session-executor:latest ./session-container
      azd env set SESSION_IMAGE_PUSHED true
```

### Bicep Parameters

Key parameters in `infra/main.bicep`:

- `openAIModelName`: GPT model to deploy (default: gpt-4o-mini)
- `maxConcurrentSessions`: Maximum parallel sessions (default: 10)
- `readySessionInstances`: Pre-warmed sessions for fast response (default: 5)
- `enableVNetIntegration`: Enable private networking (default: false)

### Custom Container Libraries

The custom session container (`session-container/Dockerfile`) includes:

- **Data Science**: numpy, pandas, matplotlib
- **Data Processing**: openpyxl, xlrd, pyarrow, lxml
- **Networking**: requests
- **Web Framework**: flask, gunicorn

## Resources Deployed

- **Azure OpenAI Service**: GPT-4o-mini deployment for agent intelligence
- **Container Apps Environment**: Serverless hosting platform
- **Dynamic Session Pool**: Custom container execution environment
- **Container Registry**: Stores custom session container image
- **User-Assigned Managed Identity**: Secure authentication across services
- **Log Analytics**: Centralized monitoring and diagnostics

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Verify managed identity has proper role assignments
2. **Session Pool Not Available**: Check that custom container was built and pushed successfully
3. **Environment Variables**: Ensure all required environment variables are configured
4. **Container Build Failures**: Check Azure Container Registry build logs

### Required Azure Roles

- **Cognitive Services OpenAI User**: For Azure OpenAI access
- **AcrPull**: For pulling custom container images from registry
- **Azure ContainerApps Session Executor**: For session pool access

### Debugging

Check the application logs in the Azure Portal:
- Navigate to your Container App → Monitoring → Log stream

Or use Azure CLI:
```bash
az containerapp logs show --name <app-name> --resource-group <resource-group>
```

View session pool status in Azure Portal:
```
Container Apps Environment → Session Pools → <your-pool-name>
```

## Additional Documentation

- [MANAGED-IDENTITY.md](docs/MANAGED-IDENTITY.md) - Keyless authentication setup and best practices
- [OBSERVABILITY.md](docs/OBSERVABILITY.md) - Application monitoring and distributed tracing
- [VNET-INTEGRATION.md](docs/VNET-INTEGRATION.md) - Private network configuration for enterprise scenarios

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- [Azure Container Apps Dynamic Sessions Overview](https://learn.microsoft.com/azure/container-apps/sessions)
- [Azure Container Apps Sessions Custom Containers](https://learn.microsoft.com/azure/container-apps/sessions-custom-container)
- [Microsoft Agent Framework Documentation](https://microsoft.github.io/agent-framework/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)
