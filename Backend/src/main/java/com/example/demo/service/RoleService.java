package com.example.demo.service;

import org.springframework.stereotype.Service;

import com.example.demo.dto.utilisateur.RoleResponse;
import com.example.demo.repository.RoleRepository;


import java.util.List;

@Service
public class RoleService {
    private final RoleRepository roleRepository;

    public RoleService(RoleRepository roleRepository) {
        this.roleRepository = roleRepository;

    }

    public List<RoleResponse> getAllRoles() {
        return roleRepository.findAll().stream()
                .map(role -> new RoleResponse(role.getId(), role.getName()))
                .toList();
    }

}
