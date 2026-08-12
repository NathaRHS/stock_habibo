package com.example.demo.service;

import org.springframework.stereotype.Service;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import com.example.demo.dto.CreateUserRequest;
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

    public UserService(UserRepository userRepository, RoleRepository roleRepository) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    // créer un utilisateur avec un rôle spécifique
    public UserResponse creerCompte(CreateUserRequest request) {
        Role role = roleRepository.findById(request.roleId())
                .orElseThrow(() -> new IllegalArgumentException("Role introuvable"));

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

    // Login
    public UserResponse login(String matricule, String password) {
        User user = userRepository.findByMatricule(matricule)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable"));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw new IllegalArgumentException("Mot de passe incorrect");
        }

        return new UserResponse(
                user.getId(),
                user.getUsername(),
                user.getMatricule(),
                user.getEmail(),
                user.getRole().getName());
    }
}
