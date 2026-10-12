package com.example.demo.dto.utilisateur;

public record UserResponse(
        Long id,
        String username,
        String matricule,
        String email,
        String role,
        // Photo de profil (« photos/<nom>.jpg »), vide si aucune.
        String imageUser
) {
}
