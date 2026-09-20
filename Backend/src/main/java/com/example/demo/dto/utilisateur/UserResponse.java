package com.example.demo.dto.utilisateur;

public record UserResponse(
        Long id,
        String username,
        String matricule,
        String email,
        String role
) {
}
