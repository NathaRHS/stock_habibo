package com.example.demo.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import com.example.demo.dto.user.UserInfoResponse;
import com.example.demo.dto.user.UserNombreOperationDto;
import com.example.demo.dto.utilisateur.CreateUserRequest;
import com.example.demo.dto.utilisateur.LoginRequest;
import com.example.demo.dto.utilisateur.LoginResponse;
import com.example.demo.dto.utilisateur.UserResponse;
import com.example.demo.entity.Role;
import com.example.demo.entity.User;
import com.example.demo.projection.UserParticipationProjection;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.UserRepository;

@Service
public class UserService {
        private final UserRepository userRepository;
        private final RoleRepository roleRepository;
        private final BCryptPasswordEncoder passwordEncoder;
        private final JwtService jwtService;
        private final FileStorageService fileStorageService;

        public UserService(
                        UserRepository userRepository,
                        RoleRepository roleRepository,
                        JwtService jwtService,
                        FileStorageService fileStorageService) {
                this.userRepository = userRepository;
                this.roleRepository = roleRepository;
                this.jwtService = jwtService;
                this.fileStorageService = fileStorageService;
                this.passwordEncoder = new BCryptPasswordEncoder();
        }

        // créer un utilisateur avec un rôle spécifique
        public UserResponse creerCompte(CreateUserRequest request) {
                Role role = roleRepository.findById(request.roleId())
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "Role introuvable : " + request.roleId()));

                String passwordHash = passwordEncoder.encode(request.password());
                User user = new User(request.username(), request.matricule(), request.email(), passwordHash, role);
                User savedUser = userRepository.save(user);

                return versResponse(savedUser);
        }

        private static final String DOSSIER_PHOTOS = "photos/";

        /**
         * Ajoute ou remplace la photo de profil. Un administrateur peut la
         * changer pour n'importe qui ; les autres seulement pour eux-mêmes.
         */
        @Transactional
        public UserResponse enregistrerPhoto(Long id, MultipartFile photo, String matriculeAppelant,
                        boolean administrateur) {
                User user = userRepository.findById(id).orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "utilisateur introuvable"));

                if (!administrateur && !user.getMatricule().equals(matriculeAppelant)) {
                        throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                        "Vous ne pouvez modifier que votre propre photo");
                }

                String anciennePhoto = user.getImageUser();
                String nomFichier = fileStorageService.enregistrerPhoto(photo);

                try {
                        user.setImageUser(DOSSIER_PHOTOS + nomFichier);
                        UserResponse reponse = versResponse(userRepository.save(user));

                        if (anciennePhoto != null && anciennePhoto.startsWith(DOSSIER_PHOTOS)) {
                                fileStorageService.supprimerPhoto(anciennePhoto.substring(DOSSIER_PHOTOS.length()));
                        }
                        return reponse;
                } catch (RuntimeException exception) {
                        // L'enregistrement a échoué : pas de fichier orphelin.
                        fileStorageService.supprimerPhoto(nomFichier);
                        throw exception;
                }
        }

        // Login utilisateur en utilisant son matricule
        public LoginResponse login(LoginRequest request) {
                User user = userRepository.findByMatricule(request.matricule())
                                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable"));

                if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
                        throw new IllegalArgumentException("Mot de passe incorrect");
                }

                UserResponse userResponse = versResponse(user);

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
                                user.getRole().getName(),
                                user.getImageUser());
        }

        public UserInfoResponse findUserInformation(Long id) {
                User user = userRepository.findById(id).orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "utilisateur introuvable"));
                List<UserParticipationProjection> UserParticipationProjection = userRepository
                                .getNombreParticipations(user.getId());

                List<UserNombreOperationDto> userNombreOperationDtos = new ArrayList<>();

                for (UserParticipationProjection userParticipationProjection2 : UserParticipationProjection) {
                        userNombreOperationDtos.add(new UserNombreOperationDto(
                                        userParticipationProjection2.getNomTypeMouvement(),
                                        userParticipationProjection2.getOperations()));

                }
                return new UserInfoResponse(
                                user.getUsername(),
                                user.getMatricule(),
                                user.getRole().getId(),
                                user.getRole().getName(),
                               userNombreOperationDtos,
                                user.getImageUser()
                );
        }
}
