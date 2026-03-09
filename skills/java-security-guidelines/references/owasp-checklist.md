# OWASP Top 10 Checklist for Java

## Quick Reference

| # | Vulnerability | Java/Spring Mitigation |
|---|--------------|----------------------|
| A01 | **Broken Access Control** | `@PreAuthorize`, RBAC, check object-level authorization |
| A02 | **Cryptographic Failures** | Use AES-GCM, BCrypt, no hardcoded secrets, TLS everywhere |
| A03 | **Injection** | Parameterized queries, Bean Validation, no eval/reflection on user input |
| A04 | **Insecure Design** | Threat modeling, input validation, rate limiting, least privilege |
| A05 | **Security Misconfiguration** | Disable debug in prod, remove default credentials, security headers |
| A06 | **Vulnerable Components** | OWASP dependency-check, Dependabot, regular updates |
| A07 | **Auth Failures** | Strong passwords (BCrypt), MFA, account lockout, session management |
| A08 | **Data Integrity Failures** | Verify signatures, use trusted CI/CD, check dependency integrity |
| A09 | **Logging Failures** | Log auth events, sanitize log input, monitor for anomalies |
| A10 | **SSRF** | Validate/whitelist URLs, block internal IPs, use allowlists |

## Spring Security Configuration Checklist

- [ ] `SecurityFilterChain` bean defined (not deprecated adapter)
- [ ] CSRF protection enabled (or explicitly disabled for stateless API)
- [ ] CORS configured with specific origins (no wildcard)
- [ ] Session management set to `STATELESS` for APIs
- [ ] Method-level security enabled (`@EnableMethodSecurity`)
- [ ] Password encoder configured (BCrypt, cost 12+)
- [ ] Security headers configured (CSP, HSTS, X-Frame-Options)
- [ ] Actuator endpoints secured
- [ ] Login rate limiting implemented
- [ ] JWT validation includes `exp`, `iss`, `aud`

## Dependency Scanning Setup

```xml
<!-- pom.xml -->
<plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <version>9.0.9</version>
    <configuration>
        <failBuildOnCVSS>7</failBuildOnCVSS>
        <suppressionFile>owasp-suppressions.xml</suppressionFile>
    </configuration>
</plugin>
```

```bash
# Run manually
mvn org.owasp:dependency-check-maven:check

# Or in CI
mvn verify -P security-check
```
