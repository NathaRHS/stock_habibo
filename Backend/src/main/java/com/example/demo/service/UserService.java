package com.example.demo.service;

import org.springframework.stereotype.Service;

import java.util.List;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import com.example.demo.dto.CreateUserRequest;
import com.example.demo.dto.LoginRequest;
import com.example.demo.dto.LoginResponse;
import com.example.demo.dto.UserResponse;
import com.example.demo.entity.Role;
import com.example.demo.entity.User;

import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.UserRepository;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final BCryptPasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public UserService(
            UserRepository userRepository,
            RoleRepository roleRepository,
            JwtService jwtService) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.jwtService = jwtService;
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    // créer un utilisateur avec un rôle spécifique
    public UserResponse creerCompte(CreateUserRequest request) {
        Role role = roleRepository.findById(request.roleId())
                .orElseThrow(() -> new IllegalArgumentException("Role introuvable : " + request.roleId()));

        String passwordHash = passwordEncoder.encode(request.password());
        User user = new User(request.username(), request.matricule(), request.email(), passwordHash, role);
        User savedUser = userRepository.save(user);

        return new UserResponse(
                savedUser.getId(),
                savedUser.getUsername(),
                savedUser.getMatricule(),
                savedUser.getEmail(),
                savedUser.getRole().getName());
    }

    // Login utilisateur en utilisant son matricule
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByMatricule(request.matricule())
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Mot de passe incorrect");
        }

        UserResponse userResponse = new UserResponse(
                user.getId(),
                user.getUsername(),
                user.getMatricule(),
                user.getEmail(),
                user.getRole().getName());

        return new LoginResponse(
                jwtService.generateToken(user),
                "Bearer",
                jwtService.getExpirationSeconds(),
                userResponse);
    }

    public List<UserResponse> getAll() {
        return userRepository.findAll().stream()
                .map(this::versResponse)
                .toList();
    }

    private UserResponse versResponse(User user) {
        return new UserResponse(
                user.getId(),
                user.getUsername(),
                user.getMatricule(),
                user.getEmail(),
                user.getRole().getName());
    }
}
