package com.example.demo.service;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;

import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
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
        verifierPdf(file, nomOriginal);
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

    public Resource chargerFichier(String nomFichier) {
        if (nomFichier == null || nomFichier.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Le nom du fichier est obligatoire");
        }

        Path fichier = uploadDirectory.resolve(nomFichier).normalize();

        if (!fichier.getParent().equals(uploadDirectory)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Nom de fichier invalide");
        }

        if (!Files.isRegularFile(fichier) || !Files.isReadable(fichier)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Fichier introuvable : " + nomFichier);
        }

        try {
            return new UrlResource(fichier.toUri());
        } catch (MalformedURLException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Impossible de lire le fichier",
                    exception);
        }
    }

    public String detecterTypeContenu(Resource fichier) {
        try {
            String typeContenu = Files.probeContentType(fichier.getFile().toPath());
            return typeContenu == null ? "application/octet-stream" : typeContenu;
        } catch (IOException exception) {
            return "application/octet-stream";
        }
    }

    // ---------------------------------------------------------------
    // Photos d'articles : images JPG, PNG ou WebP, 2 Mo maximum.
    // Reglees a part des pieces jointes, qui restent reservees aux PDF.
    // ---------------------------------------------------------------

    private static final long PHOTO_TAILLE_MAX = 2L * 1024 * 1024;
    private static final String PREFIXE_PHOTO = "photo-";

    /** Refuse un fichier qui n'est pas une vraie image acceptee (extension et signature). */
    public void verifierPhoto(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La photo est vide");
        }
        if (file.getSize() > PHOTO_TAILLE_MAX) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La photo depasse 2 Mo");
        }

        String extension = extensionPhoto(file.getOriginalFilename());
        if (!List.of("jpg", "jpeg", "png", "webp").contains(extension)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Formats acceptes : JPG, PNG ou WebP");
        }

        byte[] entete = new byte[12];
        try (var contenu = file.getInputStream()) {
            int lus = contenu.readNBytes(entete, 0, entete.length);
            if (lus < entete.length || !signatureCorrespond(entete, extension)) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Le fichier n'est pas une image valide");
            }
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "Impossible de lire la photo", exception);
        }
    }

    /** Enregistre la photo sous un nom genere et renvoie ce nom. */
    public String enregistrerPhoto(MultipartFile file) {
        verifierPhoto(file);
        String nom = PREFIXE_PHOTO + UUID.randomUUID() + "." + extensionPhoto(file.getOriginalFilename());
        Path destination = uploadDirectory.resolve(nom).normalize();

        if (!destination.getParent().equals(uploadDirectory)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Nom de fichier invalide");
        }

        try (var contenu = file.getInputStream()) {
            Files.copy(contenu, destination, StandardCopyOption.REPLACE_EXISTING);
            return nom;
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "Impossible d'enregistrer la photo", exception);
        }
    }

    /** Seuls les fichiers de photo sont lisibles par cette voie (les PDF restent proteges). */
    public Resource chargerPhoto(String nom) {
        if (nom == null || !nom.startsWith(PREFIXE_PHOTO)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Photo introuvable");
        }
        return chargerFichier(nom);
    }

    public String typeContenuPhoto(String nom) {
        return switch (extensionPhoto(nom)) {
            case "jpg", "jpeg" -> "image/jpeg";
            case "png" -> "image/png";
            case "webp" -> "image/webp";
            default -> "application/octet-stream";
        };
    }

    /** Suppression sans erreur : une photo manquante ne doit jamais bloquer une operation. */
    public void supprimerPhoto(String nom) {
        if (nom == null || !nom.startsWith(PREFIXE_PHOTO)) {
            return;
        }
        try {
            Path fichier = uploadDirectory.resolve(nom).normalize();
            if (fichier.getParent().equals(uploadDirectory)) {
                Files.deleteIfExists(fichier);
            }
        } catch (IOException exception) {
            // On ignore : le fichier restera simplement sur le disque.
        }
    }

    private String extensionPhoto(String nom) {
        if (nom == null) {
            return "";
        }
        int point = nom.lastIndexOf('.');
        return point < 0 ? "" : nom.substring(point + 1).toLowerCase();
    }

    private boolean signatureCorrespond(byte[] e, String extension) {
        return switch (extension) {
            case "jpg", "jpeg" -> (e[0] & 0xFF) == 0xFF && (e[1] & 0xFF) == 0xD8 && (e[2] & 0xFF) == 0xFF;
            case "png" -> (e[0] & 0xFF) == 0x89 && e[1] == 'P' && e[2] == 'N' && e[3] == 'G';
            case "webp" -> e[0] == 'R' && e[1] == 'I' && e[2] == 'F' && e[3] == 'F'
                    && e[8] == 'W' && e[9] == 'E' && e[10] == 'B' && e[11] == 'P';
            default -> false;
        };
    }

    private void verifierPdf(MultipartFile file, String nomOriginal) {
        if (!nomOriginal.toLowerCase().endsWith(".pdf")) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Seuls les fichiers PDF sont acceptes");
        }

        byte[] entete = new byte[5];

        try (var contenu = file.getInputStream()) {
            int lus = contenu.readNBytes(entete, 0, entete.length);

            if (lus < entete.length || !new String(entete, StandardCharsets.US_ASCII).equals("%PDF-")) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Le fichier n'est pas un PDF valide");
            }
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Impossible de lire le fichier",
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
