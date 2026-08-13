package com.example.demo.Controller;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.CreateUserRequest;
import com.example.demo.dto.UserResponse;
import com.example.demo.service.UserService;

@RestController

@RequestMapping("/user")
public class UserController {

    private UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/creerCompte")
    public UserResponse creerCompte(@RequestBody CreateUserRequest request) {
        return userService.creerCompte(request);
    }

    @PostMapping("/login")
    public UserResponse login(@RequestBody CreateUserRequest request) {
        return userService.login(request.matricule(), request.password());
    }


}
