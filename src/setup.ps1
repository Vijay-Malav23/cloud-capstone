$pkgDir = "src/main/java/com/capstone/cloud"

# 1. Models
$roleContent = @"
package com.capstone.cloud.model;

public enum Role {
    ROLE_USER,
    ROLE_ADMIN
}
"@
Set-Content -Path "$pkgDir/model/Role.java" -Value $roleContent -Encoding UTF8

$userContent = @"
package com.capstone.cloud.model;

import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    @Column(nullable = false)
    private String password;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    public User() {}

    public User(String username, String password, Role role) {
        this.username = username;
        this.password = password;
        this.role = role;
    }

    public Long getId() { return id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }
}
"@
Set-Content -Path "$pkgDir/model/User.java" -Value $userContent -Encoding UTF8

$resourceContent = @"
package com.capstone.cloud.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "resource_items")
public class ResourceItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    private String description;
    private String category;
    private String status;
    private LocalDateTime createdAt = LocalDateTime.now();

    public ResourceItem() {}

    public ResourceItem(String title, String description, String category, String status) {
        this.title = title;
        this.description = description;
        this.category = category;
        this.status = status;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
"@
Set-Content -Path "$pkgDir/model/ResourceItem.java" -Value $resourceContent -Encoding UTF8

# 2. Repositories
$userRepoContent = @"
package com.capstone.cloud.repository;

import com.capstone.cloud.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Boolean existsByUsername(String username);
}
"@
Set-Content -Path "$pkgDir/repository/UserRepository.java" -Value $userRepoContent -Encoding UTF8

$resourceRepoContent = @"
package com.capstone.cloud.repository;

import com.capstone.cloud.model.ResourceItem;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ResourceItemRepository extends JpaRepository<ResourceItem, Long> {
}
"@
Set-Content -Path "$pkgDir/repository/ResourceItemRepository.java" -Value $resourceRepoContent -Encoding UTF8

# 3. Security
$jwtUtilsContent = @"
package com.capstone.cloud.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;

@Component
public class JwtUtils {

    @Value("`$"{app.jwt.secret}")
    private String jwtSecret;

    @Value("`$"{app.jwt.expiration-ms}")
    private int jwtExpirationMs;

    private Key getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }

    public String generateToken(String username, String role) {
        return Jwts.builder()
                .setSubject(username)
                .claim("role", role)
                .setIssuedAt(new Date())
                .setExpiration(new Date((new Date()).getTime() + jwtExpirationMs))
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    public String getUsernameFromToken(String token) {
        return Jwts.parserBuilder().setSigningKey(getSigningKey()).build()
                .parseClaimsJws(token).getBody().getSubject();
    }

    public String getRoleFromToken(String token) {
        return (String) Jwts.parserBuilder().setSigningKey(getSigningKey()).build()
                .parseClaimsJws(token).getBody().get("role");
    }

    public boolean validateToken(String authToken) {
        try {
            Jwts.parserBuilder().setSigningKey(getSigningKey()).build().parseClaimsJws(authToken);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
"@
Set-Content -Path "$pkgDir/security/JwtUtils.java" -Value $jwtUtilsContent -Encoding UTF8

$jwtFilterContent = @"
package com.capstone.cloud.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtils jwtUtils;

    public JwtAuthFilter(JwtUtils jwtUtils) {
        this.jwtUtils = jwtUtils;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtUtils.validateToken(token)) {
                String username = jwtUtils.getUsernameFromToken(token);
                String role = jwtUtils.getRoleFromToken(token);

                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        username, null, Collections.singletonList(new SimpleGrantedAuthority(role))
                );
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }
        filterChain.doFilter(request, response);
    }
}
"@
Set-Content -Path "$pkgDir/security/JwtAuthFilter.java" -Value $jwtFilterContent -Encoding UTF8

# 4. Config
$secConfigContent = @"
package com.capstone.cloud.config;

import com.capstone.cloud.security.JwtAuthFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**", "/swagger-ui/**", "/v3/api-docs/**", "/actuator/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/resources/**").hasAnyAuthority("ROLE_USER", "ROLE_ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/resources/**").hasAnyAuthority("ROLE_USER", "ROLE_ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/resources/**").hasAuthority("ROLE_ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/resources/**").hasAuthority("ROLE_ADMIN")
                .anyRequest().authenticated()
            );

        http.addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
        return http;
    }
}
"@
Set-Content -Path "$pkgDir/config/SecurityConfig.java" -Value $secConfigContent -Encoding UTF8

$openApiConfigContent = @"
package com.capstone.cloud.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info().title("Cloud Capstone Backend API").version("1.0.0")
                .description("Cloud Architecture API with RBAC, Dockerization, and Automated CI/CD"))
            .addSecurityItem(new SecurityRequirement().addList("BearerAuth"))
            .components(new Components().addSecuritySchemes("BearerAuth",
                new SecurityScheme()
                    .name("BearerAuth")
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")));
    }
}
"@
Set-Content -Path "$pkgDir/config/OpenApiConfig.java" -Value $openApiConfigContent -Encoding UTF8

# 5. Controllers
$authControllerContent = @"
package com.capstone.cloud.controller;

import com.capstone.cloud.model.Role;
import com.capstone.cloud.model.User;
import com.capstone.cloud.repository.UserRepository;
import com.capstone.cloud.security.JwtUtils;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    public AuthController(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtUtils jwtUtils) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtils = jwtUtils;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, String> request) {
        String username = request.get("username");
        String password = request.get("password");
        String roleStr = request.getOrDefault("role", "ROLE_USER");

        if (userRepository.existsByUsername(username)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Username already exists"));
        }

        Role role = roleStr.equalsIgnoreCase("ROLE_ADMIN") ? Role.ROLE_ADMIN : Role.ROLE_USER;
        User user = new User(username, passwordEncoder.encode(password), role);
        userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "User registered successfully", "role", role.name()));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> request) {
        String username = request.get("username");
        String password = request.get("password");

        User user = userRepository.findByUsername(username).orElse(null);

        if (user == null || !passwordEncoder.matches(password, user.getPassword())) {
            return ResponseEntity.status(401).body(Map.of("message", "Invalid credentials"));
        }

        String token = jwtUtils.generateToken(user.getUsername(), user.getRole().name());
        return ResponseEntity.ok(Map.of("token", token, "username", user.getUsername(), "role", user.getRole().name()));
    }
}
"@
Set-Content -Path "$pkgDir/controller/AuthController.java" -Value $authControllerContent -Encoding UTF8

$resourceControllerContent = @"
package com.capstone.cloud.controller;

import com.capstone.cloud.model.ResourceItem;
import com.capstone.cloud.repository.ResourceItemRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/resources")
public class ResourceController {

    private final ResourceItemRepository repository;

    public ResourceController(ResourceItemRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<ResourceItem> getAllResources() {
        return repository.findAll();
    }

    @PostMapping
    public ResponseEntity<ResourceItem> createResource(@RequestBody ResourceItem item) {
        return ResponseEntity.ok(repository.save(item));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteResource(@PathVariable Long id) {
        if (!repository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        repository.deleteById(id);
        return ResponseEntity.ok(Map.of("message", "Resource deleted successfully by Admin"));
    }
}
"@
Set-Content -Path "$pkgDir/controller/ResourceController.java" -Value $resourceControllerContent -Encoding UTF8

Write-Host "All Java files written successfully!" -ForegroundColor Green