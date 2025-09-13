# Security Policy

This document outlines the security policy and procedures for the `n8n-stack` project.

## Our Approach to Security

Security is a primary focus of this project. The architecture is designed to be secure by default, leveraging modern tools and best practices to protect your n8n instance. This includes:

- **Zero Trust Network Access:** Using Cloudflare Tunnel to ensure that no inbound ports are opened on the host server, significantly reducing the external attack surface.
- **Principle of Least Privilege:** Components are configured with the minimum necessary permissions.
- **Dependency Management:** Using specific image versions is recommended to ensure stability and control over updates.

## Reporting a Vulnerability

We take all security vulnerabilities seriously. To ensure reports are handled securely and privately, we use **GitHub Private Vulnerability Reporting**. This is the preferred and most secure method for reporting.

**How to Submit a Report:**

1.  Navigate to the **"Security"** tab of this repository.
2.  Click the **"Report a vulnerability"** button.
3.  Fill out the form with a detailed description of the vulnerability, its potential impact, and steps to reproduce it.

This will open a private advisory, allowing us to collaborate on a fix without public disclosure.

**Please do not open a public GitHub issue for security vulnerabilities.**

## Security Model Overview

The security of this stack is based on a layered approach:

1.  **Cloudflare:** Provides the first line of defense, including a Web Application Firewall (WAF), DDoS mitigation, and encrypted TLS termination.
2.  **Cloudflare Tunnel:** Creates a secure, outbound-only connection from the `cloudflared` container to the Cloudflare network. This means the host server is not directly exposed to the internet.
3.  **Traefik Reverse Proxy:** Manages internal traffic, routing requests to the appropriate services. It is configured to separate UI and webhook traffic for n8n.
4.  **Container Isolation:** All services run in isolated containers on a dedicated Docker network, limiting their ability to interact with each other and the host system.

For a detailed breakdown of the traffic flow and the security at each step, please see the [Ingress & Egress Traffic Security Analysis](./docs/traffic-security-analysis.md).
