# Deployment and DNS Configuration

This document explains how to expose the UUID service via a custom domain using API Gateway, ACM, and Cloudflare DNS.

The Terraform in `infra/` can optionally create:

- An ACM certificate (DNS validated) for a custom API subdomain (e.g. `api.example.com`).
- An API Gateway custom domain bound to that certificate.
- A base path mapping so the service is available under a path on that subdomain (by default: `/uuid_service`).

You configure DNS in Cloudflare so traffic from your domain reaches API Gateway and ACM can validate and auto‑renew the certificate.

---

## 1. Prerequisites

- You own a domain managed by Cloudflare.
- The `infra` stack has been applied with:
  - `api_custom_domain_name` set, e.g. `api_custom_domain_name = "api.example.com"`.
  - Optional `api_custom_path` set (defaults to `"uuid_service"`).
- You are using **DNS-only** (grey-cloud) for this API endpoint in Cloudflare.

Terraform resources involved:

- `aws_acm_certificate.api_custom_domain`
- `aws_apigatewayv2_domain_name.custom`
- `aws_apigatewayv2_api_mapping.uuid_service`

---

## 2. Get the DNS details from Terraform

From the repo root:

```bash
cd infra

# Ensure state is up to date
tofu init
tofu apply   # or have CI do this

# Read the outputs needed for DNS
tofu output api_custom_domain_name
tofu output api_custom_domain_target
tofu output api_certificate_dns_validation_records
```

Example output (shape, not exact values):

```hcl
api_custom_domain_name = "api.example.com"
api_custom_domain_target = "d-abcdefghij.execute-api.us-east-1.amazonaws.com"
api_certificate_dns_validation_records = [
  {
    name  = "_abc123.api.example.com"
    type  = "CNAME"
    value = "_xyz987.acm-validations.aws"
  }
]
```

You will use these values to create DNS records in Cloudflare.

---

## 3. Add the ACM validation CNAME in Cloudflare

ACM uses DNS validation to prove you control the domain and to enable automatic renewal.

1. Log in to Cloudflare and open the DNS settings for your domain (e.g. `example.com`).
2. For each entry in `api_certificate_dns_validation_records`, create a **CNAME** record:
   - **Type**: `CNAME`
   - **Name**: the `name` from the output, but entered as Cloudflare expects. For example, if Terraform shows `name = "_abc123.api.example.com"`, you typically enter `_abc123.api` in the **Name** field (Cloudflare will append the domain).
   - **Target**: the `value` from the output, e.g. `_xyz987.acm-validations.aws`.
   - **Proxy status**: **DNS only** (grey cloud).

You only need to create these validation records once. ACM will periodically re‑validate using the same CNAME and auto‑renew the certificate without further changes.

---

## 4. Add the API CNAME in Cloudflare

Next, point your chosen API hostname (e.g. `api.example.com`) at the API Gateway custom domain target.

1. In Cloudflare DNS for your domain, create another **CNAME** record:
   - **Type**: `CNAME`
   - **Name**: the host part of `api_custom_domain_name`.
     - If `api_custom_domain_name = "api.example.com"`, use `api`.
   - **Target**: the value of `api_custom_domain_target`, e.g. `d-abcdefghij.execute-api.us-east-1.amazonaws.com`.
   - **Proxy status**: **DNS only** (grey cloud).

This CNAME sends client traffic for `https://api.example.com/...` directly to the API Gateway regional endpoint.

---

## 5. URL structure and paths

The Terraform module configures:

- An HTTP API with a route: `GET /`.
- (Optional) a custom domain with a base path mapping controlled by `api_custom_path`.

Given:

```hcl
api_custom_domain_name = "api.example.com"
api_custom_path        = "uuid_service"  # default
```

Your public URL pattern for the UUID endpoint will be:

```text
https://api.example.com/<api_custom_path>
```

With the defaults shown above (`api_custom_path = "uuid_service"`), that is:

```text
https://api.example.com/uuid_service
```

Notes:

- The **root** of the subdomain (`https://api.example.com/`) is not used by this service; traffic is only mapped under `/{api_custom_path}`.
- You can change `api_custom_path` in `infra/terraform.tfvars` if you want a different prefix, then re‑apply the stack.

The original execute‑api URL (without the custom domain) is still available via the `api_endpoint` Terraform output and is used by `scripts/smoke_test.py`.

---

## 6. Verification checklist

After setting up DNS:

1. Wait a few minutes for DNS and ACM.
2. In the AWS console (ACM), confirm the certificate status is **Issued**.
3. In the AWS console (API Gateway → Custom domain names), confirm the domain shows as deployed.
4. From your terminal, test the public URL (replacing the domain and path as appropriate):

   ```bash
   curl -i "https://api.example.com/uuid_service"
   ```

You should receive an HTTP 200 with a JSON body containing a valid UUIDv4.

Once this is working, your UUID service is publicly accessible over HTTPS with an auto‑renewing ACM certificate fronted by Cloudflare DNS.
