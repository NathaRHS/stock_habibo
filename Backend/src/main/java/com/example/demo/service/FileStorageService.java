package com.example.demo.service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@Service
public class FileStorageService {

    private final Path uploadDirectory = Path.of("uploads")
            .toAbsolutePath()
            .normalize();

    public FileStorageService() {
        try {
            Files.createDirectories(uploadDirectory);
        } catch (IOException exception) {
            throw new IllegalStateException(
                    "Impossible de creer le dossier uploads", exception);
        }
    }

    public String enregistrerFichier(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le fichier est obligatoire");
        }

        String nomOriginal = nettoyerNomOriginal(file.getOriginalFilename());
        String nomUnique = UUID.randomUUID() + "_" + nomOriginal;
        Path destination = uploadDirectory.resolve(nomUnique).normalize();

        if (!destination.getParent().equals(uploadDirectory)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Nom de fichier invalide");
        }

        try (var contenu = file.getInputStream()) {
            Files.copy(contenu, destination, StandardCopyOption.REPLACE_EXISTING);
            return nomUnique;
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Impossible d'enregistrer le fichier",
                    exception);
        }
    }

    private String nettoyerNomOriginal(String nomOriginal) {
        if (nomOriginal == null || nomOriginal.isBlank()) {
            return "fichier";
        }

        String nomNettoye = StringUtils.cleanPath(nomOriginal);
        nomNettoye = nomNettoye.replace('\\', '/');
        nomNettoye = nomNettoye.substring(nomNettoye.lastIndexOf('/') + 1);

        if (nomNettoye.isBlank() || nomNettoye.equals(".") || nomNettoye.equals("..")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Nom de fichier invalide");
        }

        return nomNettoye;
    }
}
