package com.example.demo.service;

import java.math.BigDecimal;

import org.springframework.stereotype.Service;

import com.example.demo.entity.Role;
import com.example.demo.entity.User;
import com.example.demo.exception.SoldeInsuffisantException;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.UserRepository;

import jakarta.persistence.EntityManager;

import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class RoleService {
    private final RoleRepository roleRepository;
    private final EntityManager entityManager;

    public RoleService(RoleRepository roleRepository, EntityManager entityManager) {
        this.roleRepository = roleRepository;
        this.entityManager = entityManager;

    }

    public List<Role> getAllRoles() {
        return roleRepository.findAll();
    }

  

}