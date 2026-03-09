---
name: java-security-guidelines
description: >
  Java application security best practices covering OWASP Top 10, Spring Security,
  input validation, cryptography, and secure coding. 50+ rules for authentication,
  SQL injection prevention, XSS, CSRF, and dependency scanning. Use when auditing
  security, implementing auth, or hardening Java applications. Triggers: "Security
  review", "OWASP", "SQL injection", "XSS", "authentication", "Spring Security",
  "vulnerability", "secure coding".
---

# Java Security Guidelines

Production-grade security patterns for Java applications. Covers OWASP Top 10, Spring Security, and secure coding practices.

## Rules

### 1. Input Validation & Sanitization (Critical)

| # | Rule | Description |
|---|------|-------------|
| IV1 | **Validate all external input** | Request bodies, query params, path variables, headers. Trust nothing. |
| IV2 | **Use Bean Validation** | `@NotBlank`, `@Size`, `@Pattern`, `@Email` on DTOs with `@Valid`. |
| IV3 | **Reject unknown fields** | `spring.jackson.deserialization.fail-on-unknown-properties=true`. |
| IV4 | **Limit request sizes** | `spring.servlet.multipart.max-file-size=10MB`, `server.max-http-request-header-size=8KB`. |
| IV5 | **Sanitize HTML output** | Use OWASP Java HTML Sanitizer for user-generated content. |

### 2. SQL Injection Prevention (Critical)

| # | Rule | Description |
|---|------|-------------|
| SQ1 | **Never concatenate SQL** | `"SELECT * FROM users WHERE id = " + id` is ALWAYS vulnerable. |
| SQ2 | **Use parameterized queries** | JPA: `@Query` with `:param`. JDBC: `PreparedStatement` with `?`. |
| SQ3 | **Use JPA/Hibernate** | ORM generates parameterized SQL. Still validate sort/filter inputs. |
| SQ4 | **Whitelist dynamic ORDER BY** | Never pass user input directly to `ORDER BY`. Map to allowed column names. |

```java
// BAD: SQL injection vulnerable
@Query(value = "SELECT * FROM users WHERE name = '" + name + "'", nativeQuery = true)

// GOOD: Parameterized query
@Query("SELECT u FROM User u WHERE u.name = :name")
List<User> findByName(@Param("name") String name);

// GOOD: Dynamic sort with whitelist
private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("name", "email", "createdAt");

public Page<User> findAll(String sortBy, String direction, Pageable pageable) {
    if (!ALLOWED_SORT_FIELDS.contains(sortBy)) {
        throw new IllegalArgumentException("Invalid sort field: " + sortBy);
    }
    Sort sort = Sort.by(Sort.Direction.fromString(direction), sortBy);
    return userRepository.findAll(PageRequest.of(pageable.getPageNumber(),
        pageable.getPageSize(), sort));
}
```

### 3. Authentication & Authorization (Critical)

| # | Rule | Description |
|---|------|-------------|
| AU1 | **Use BCrypt for passwords** | Cost factor ≥ 12. `BCryptPasswordEncoder`. |
| AU2 | **Implement account lockout** | Lock after N failed attempts. Exponential backoff. |
| AU3 | **Use short-lived JWT tokens** | Access token: 15-30 min. Refresh token: 7-30 days. |
| AU4 | **Validate JWT claims** | Check `exp`, `iss`, `aud`. Verify signature algorithm. |
| AU5 | **Use method-level authorization** | `@PreAuthorize` on service methods, not just URL patterns. |
| AU6 | **Never expose user enumeration** | Same error for "user not found" and "wrong password". |

### 4. Cryptography & Secrets (High)

| # | Rule | Description |
|---|------|-------------|
| CR1 | **Use strong algorithms** | AES-256-GCM for encryption. SHA-256+ for hashing. RSA-2048+ for signatures. |
| CR2 | **Use SecureRandom** | Never `java.util.Random` for security-sensitive operations. |
| CR3 | **Store secrets externally** | Vault, AWS Secrets Manager, env variables. Never in source code or config files. |
| CR4 | **Rotate secrets regularly** | API keys, JWT signing keys, database passwords. |

```java
// Secure random token generation
public static String generateToken(int byteLength) {
    byte[] bytes = new byte[byteLength];
    new SecureRandom().nextBytes(bytes);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
}

// AES-GCM encryption
public static byte[] encrypt(byte[] plaintext, SecretKey key) throws Exception {
    Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
    byte[] iv = new byte[12];
    new SecureRandom().nextBytes(iv);
    cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(128, iv));
    byte[] ciphertext = cipher.doFinal(plaintext);
    // Prepend IV to ciphertext
    return ByteBuffer.allocate(iv.length + ciphertext.length)
        .put(iv).put(ciphertext).array();
}
```

### 5. HTTP Security Headers (High)

| # | Rule | Description |
|---|------|-------------|
| HD1 | **Content-Security-Policy** | Prevent XSS. `default-src 'self'`. |
| HD2 | **Strict-Transport-Security** | Force HTTPS. `max-age=31536000; includeSubDomains`. |
| HD3 | **X-Content-Type-Options** | `nosniff` — prevents MIME type sniffing. |
| HD4 | **X-Frame-Options** | `DENY` or `SAMEORIGIN` — prevents clickjacking. |

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    return http
        .headers(headers -> headers
            .contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'self'"))
            .frameOptions(frame -> frame.deny())
            .httpStrictTransportSecurity(hsts -> hsts
                .includeSubDomains(true)
                .maxAgeInSeconds(31536000))
        )
        // ... other config
        .build();
}
```

### 6. Dependency Vulnerability Scanning (High)

| # | Rule | Description |
|---|------|-------------|
| DV1 | **Scan with OWASP Dependency-Check** | `mvn org.owasp:dependency-check-maven:check`. Run in CI. |
| DV2 | **Keep dependencies updated** | `mvn versions:display-dependency-updates`. Automate with Dependabot. |
| DV3 | **Fail build on critical CVEs** | Set `failBuildOnCVSS=7` in dependency-check configuration. |

### 7. Logging Security Events (Medium)

| # | Rule | Description |
|---|------|-------------|
| LG1 | **Log authentication events** | Login success, failure, lockout, password reset. |
| LG2 | **Never log sensitive data** | Mask passwords, tokens, SSNs, credit card numbers. |
| LG3 | **Log authorization failures** | 403 responses with user and requested resource. |
| LG4 | **Prevent log injection** | Sanitize user input before logging. Use parameterized logging. |

```java
// BAD: Log injection vulnerable
log.info("User login: " + username); // username could contain \n + fake log entries

// GOOD: Parameterized logging (SLF4J auto-escapes)
log.info("User login: {}", username);

// GOOD: Mask sensitive data
log.info("Payment processed for card ending in {}", last4Digits(cardNumber));
```

For OWASP checklist, see `references/owasp-checklist.md`.
