package com.example.demo.dto;

public record CreateUserRequest(
                String username,
                String matricule,
                String email,
                String password,
                Long roleId,
                Long type_conditionnement_id) {
}
