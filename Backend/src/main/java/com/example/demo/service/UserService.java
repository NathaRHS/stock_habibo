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
import com.example.demo.entity.CibleEvenement;
import com.example.demo.entity.Role;
import com.example.demo.entity.TypeEvenementUser;
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
        private final JournalUserService journalUserService;

        public UserService(
                        UserRepository userRepository,
                        RoleRepository roleRepository,
                        JwtService jwtService,
                        FileStorageService fileStorageService,
                        JournalUserService journalUserService) {
                this.userRepository = userRepository;
                this.roleRepository = roleRepository;
                this.jwtService = jwtService;
                this.fileStorageService = fileStorageService;
                this.journalUserService = journalUserService;
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

                // L'acteur est l'administrateur connecte, pas le compte cree.
                journalUserService.enregistrer(
                                TypeEvenementUser.COMPTE_CREE,
                                CibleEvenement.USER,
                                savedUser.getId(),
                                savedUser.getMatricule() + " (" + role.getName() + ")");

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

                        journalUserService.enregistrer(
                                        TypeEvenementUser.PHOTO_UTILISATEUR_CHANGEE,
                                        CibleEvenement.USER,
                                        user.getId(),
                                        "pour " + user.getMatricule());

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
                User user = userRepository.findByMatricule(request.matricule()).orElse(null);

                if (user == null) {
                        // La trace est ecrite dans sa propre transaction : elle reste
                        // meme si la connexion est refusee.
                        journalUserService.enregistrerEchecConnexion(request.matricule(), "Matricule inconnu");
                        throw new IllegalArgumentException("Utilisateur introuvable");
                }

                if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
                        journalUserService.enregistrerEchecConnexion(request.matricule(), "Mot de passe incorrect");
                        throw new IllegalArgumentException("Mot de passe incorrect");
                }

                UserResponse userResponse = versResponse(user);

                // Pas encore de jeton a ce stade : l'acteur est donne explicitement.
                journalUserService.enregistrerPour(
                                user,
                                TypeEvenementUser.CONNEXION_REUSSIE,
                                CibleEvenement.USER,
                                user.getId(),
                                "rôle " + user.getRole().getName());

                return new LoginResponse(
                                jwtService.generateToken(user),
                                "Bearer",
                                jwtService.getExpirationSeconds(),
                                userResponse);
        }

        // Le jeton reste valide jusqu'a son expiration (API sans etat) : cet appel
        // sert a tracer le depart, le front efface ensuite son jeton.
        public void deconnecter(String matricule) {
                User user = userRepository.findByMatricule(matricule).orElse(null);
                journalUserService.enregistrerPour(
                                user,
                                TypeEvenementUser.DECONNEXION,
                                CibleEvenement.USER,
                                user == null ? null : user.getId(),
                                null);
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
