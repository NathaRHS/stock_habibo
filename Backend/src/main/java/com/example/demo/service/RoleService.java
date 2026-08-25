package com.example.demo.service;


import org.springframework.stereotype.Service;

import com.example.demo.entity.Role;
import com.example.demo.dto.RoleResponse;
import com.example.demo.repository.RoleRepository;

import jakarta.persistence.EntityManager;

import java.util.List;

@Service
public class RoleService {
    private final RoleRepository roleRepository;
    private final EntityManager entityManager;

    public RoleService(RoleRepository roleRepository, EntityManager entityManager) {
        this.roleRepository = roleRepository;
        this.entityManager = entityManager;

    }

    public List<RoleResponse> getAllRoles() {
        return roleRepository.findAll().stream()
                .map(role -> new RoleResponse(role.getId(), role.getName()))
                .toList();
    }

  

}
