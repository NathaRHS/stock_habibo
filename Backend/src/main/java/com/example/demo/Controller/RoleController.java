package com.example.demo.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.example.demo.dto.RoleResponse;
import com.example.demo.service.RoleService;

@RestController
@RequestMapping("/roles")
public class RoleController {

    private RoleService roleService;

    public RoleController(RoleService role) {
        this.roleService = role;
    }

    @GetMapping("/showRoles")
    public List<RoleResponse> showRoles() {
        return roleService.getAllRoles();

    }
}
