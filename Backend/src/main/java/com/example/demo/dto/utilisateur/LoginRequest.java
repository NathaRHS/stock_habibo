package com.example.demo.dto.utilisateur;

public record LoginRequest(
        String matricule,
        String password) {
}
