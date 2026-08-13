package com.example.demo.dto;

public record LoginResponse(
        String token,
        String tokenType,
        long expiresIn,
        UserResponse user) {
}
