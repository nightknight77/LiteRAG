# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of LiteRAG seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please do NOT report security vulnerabilities through public GitHub issues.

Instead, please report them via:

1. **GitHub Security Advisories**: Use the "Report a vulnerability" button in the Security tab of this repository
2. **Email**: Send details to the project maintainers (create a GitHub issue requesting contact information for sensitive reports)

### What to Include

Please include the following information in your report:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit the issue

### Response Timeline

- **Acknowledgment**: Within 48 hours of receiving your report
- **Initial Assessment**: Within 5 business days
- **Status Updates**: Weekly updates on progress
- **Resolution**: Coordinated disclosure timeline based on severity

## Security Considerations

### Deployment Security

When deploying LiteRAG:

- **Network Security**: Run behind a firewall, restrict port access
- **Authentication**: Consider adding authentication for production use
- **HTTPS**: Use HTTPS in production environments
- **Container Security**: Keep Docker images updated, use non-root users
- **Data Security**: Secure sensitive documents, use encrypted storage
- **Environment Variables**: Never commit secrets to version control

### Known Limitations

- **No Built-in Authentication**: The system is designed for local/trusted network use
- **File Upload**: File upload endpoint accepts any text file - validate in production
- **Resource Limits**: No built-in rate limiting or resource constraints
- **Logging**: May log sensitive information in debug mode

### Secure Configuration

Example secure deployment considerations:

```yaml
# docker-compose.yml - Production considerations
services:
  rag-api:
    environment:
      - LOG_LEVEL=INFO  # Avoid DEBUG in production
    # Add reverse proxy with authentication
    # Configure resource limits
    
  qdrant:
    # Consider authentication and encryption
    # Restrict network access
```

## Security Best Practices

### For Contributors

- **Dependencies**: Keep dependencies updated, use `poetry update`
- **Secrets**: Never commit API keys, passwords, or sensitive data
- **Input Validation**: Validate all user inputs
- **Error Handling**: Don't expose internal details in error messages
- **Logging**: Be careful not to log sensitive information

### For Users

- **Network**: Run on isolated networks when possible
- **Updates**: Keep the system updated with latest security patches
- **Monitoring**: Monitor for unusual activity or resource usage
- **Backups**: Regularly backup your data and configurations
- **Access Control**: Limit who can access the system

## Vulnerability Disclosure Policy

- We will acknowledge receipt of vulnerability reports within 48 hours
- We will provide an estimated timeline for fixes within 5 business days
- We will notify you when the vulnerability is fixed
- We will publicly disclose the vulnerability after a fix is released (with your permission)
- We will credit you for the discovery unless you prefer to remain anonymous

Thank you for helping keep LiteRAG and its users safe!