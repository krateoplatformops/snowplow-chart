# Krateo AuthN Helm Chart

This is a [Helm Chart](https://helm.sh/docs/topics/charts/) for [Krateo Snowplow](https://github.com/krateoplatformops/snowplow).

## Requirements

Snowplow verifies the RS256 JWTs issued by authn. It needs authn's **RSA public
key** (the public half of authn's signing keypair) — never a shared secret and
never the private key.

Before installing, create a Secret in the release namespace holding the
PEM-encoded public key. By default the chart expects a Secret named
`authn-jwt-public-key` with the key under `public.pem` (configurable via
`jwt.publicKeySecretName` / `jwt.publicKeySecretKey`). It is mounted into the pod
as a file at `/etc/snowplow/jwt/public.pem` and passed to snowplow via
`JWT_PUBLIC_KEY_FILE`.

Derive the public key from authn's private key and create the Secret:

```sh
# Export authn's public key from the private key it signs with.
openssl rsa -in private.pem -pubout -out public.pem

# Create the Secret (the key name must match .Values.jwt.publicKeySecretKey).
kubectl create secret generic authn-jwt-public-key \
  --namespace <snowplow-namespace> \
  --from-file=public.pem=./public.pem
```

> **Migrating from HS256?** Earlier versions used a shared symmetric secret
> (`stringData.JWT_SIGN_KEY`). That is no longer supported — replace it with
> authn's PEM public key as shown above. authn must be issuing RS256 tokens (it
> also publishes the key at `/.well-known/jwks.json`).

## How to install

```sh
helm repo add krateo https://charts.krateo.io
helm repo update krateo
helm install snowplow krateo/snowplow
```
