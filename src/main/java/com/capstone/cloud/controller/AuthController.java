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
