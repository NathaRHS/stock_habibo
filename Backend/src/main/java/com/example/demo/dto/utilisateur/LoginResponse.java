package com.example.demo.dto.utilisateur;

public record LoginResponse(
        String token,
        String tokenType,
        long expiresIn,
        UserResponse user) {
}
