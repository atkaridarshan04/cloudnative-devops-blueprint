# 🕸️ Service Mesh

> Hands-on guide: [Istio.md](../Istio.md)

## The problem it solves

Once you have more than a couple of services talking to each other, you start wanting the same handful of things for *all* of them: encrypted traffic, retries/timeouts, fine-grained authorization, and visibility into who's calling whom and how slowly. You could build this into every service — a TLS library here, a retry wrapper there — but then every language/framework needs its own implementation, and it's inconsistent by construction.

A service mesh moves all of that out of application code and into the platform.

## The sidecar pattern

Istio injects an Envoy proxy container into every application pod. All inbound and outbound traffic for that pod is transparently redirected through its sidecar — the application keeps making plain HTTP/gRPC calls and has no idea a proxy is involved.

- **Data plane** = the Envoy sidecars, one per pod, actually handling traffic.
- **Control plane** = `istiod`, which configures every sidecar (routing rules, TLS certs, policies) so they act consistently.

Because the proxy sees *every* request, the mesh can apply mTLS, retries, and collect metrics/traces without a single line of application code changing.

## mTLS and zero-trust

By default, Kubernetes Service-to-Service traffic is plaintext and unauthenticated — anything inside the cluster network can call anything else. Istio's `PeerAuthentication` set to `STRICT` forces every sidecar to negotiate mutual TLS, so both sides prove their identity and traffic is encrypted, with no app-level cert handling.

On top of encryption, `AuthorizationPolicy` adds authorization: a `deny-all` policy blocks everything by default, and explicit allow rules permit only the specific caller → callee pairs that should exist (e.g. only the `frontend` ServiceAccount may call `backend` on `/books*`). This is the "zero-trust" model — nothing is trusted by default just because it's on the same network; identity and intent are checked on every call.

## Traffic management

Plain Kubernetes `Service` objects only do basic load balancing. Istio's `VirtualService` (routing rules — path matching, header matching, traffic splitting by weight) and `DestinationRule` (policies for a destination — load balancing algorithm, connection pool limits, outlier detection/circuit breaking) give you application-layer control over *how* traffic reaches a service, independent of the underlying Deployment.

## Observability

Because every request already passes through a sidecar, the mesh gets distributed tracing, per-hop latency/error metrics, and a live service topology (what Kiali visualizes) for free — again, without instrumenting application code.

## The tradeoff

None of this is free: every request now hops through two extra proxies (client sidecar → network → server sidecar), each pod carries an extra container's worth of CPU/memory, and the mesh itself (control plane, CRDs, policies) is another system to operate and debug. For a handful of services owned by one team with no compliance requirement for encrypted internal traffic, a mesh is usually more operational overhead than it's worth — it pays off once you have enough services, teams, or a real mTLS/zero-trust requirement that hand-rolling it per-service would be worse.
