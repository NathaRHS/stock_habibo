package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.example.demo.dto.user.UserInfoResponse;
import com.example.demo.dto.utilisateur.CreateUserRequest;
import com.example.demo.dto.utilisateur.LoginRequest;
import com.example.demo.dto.utilisateur.LoginResponse;
import com.example.demo.dto.utilisateur.UserResponse;
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

    @GetMapping
    public List<UserResponse> getAll(){
        return userService.getAll();
    }

    // Photo de profil : l'administrateur la change pour tous, les autres pour
    // eux-mêmes seulement (contrôlé dans le service).
    @PutMapping(value = "/{id}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public UserResponse updatePhoto(
            @PathVariable Long id,
            @RequestPart("photo") MultipartFile photo,
            @AuthenticationPrincipal Jwt jwt) {
        List<String> roles = jwt.getClaimAsStringList("roles");
        boolean administrateur = roles != null && roles.contains("ADMIN");
        return userService.enregistrerPhoto(id, photo, jwt.getSubject(), administrateur);
    }

    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request) {
        return userService.login(request);
    }

    // Trace la deconnexion dans le journal d'activite (voir SecurityConfig :
    // tout utilisateur connecte).
    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@AuthenticationPrincipal Jwt jwt) {
        userService.deconnecter(jwt.getSubject());
    }


    @GetMapping ("/nombreOperations/{id}")
    public UserInfoResponse getUserInfo(@PathVariable Long id){
        return userService.findUserInformation(id);
    }


}
