package com.example.demo.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.picking.PickingCreateRequest;
import com.example.demo.dto.picking.PickingResponse;
import com.example.demo.dto.picking.PickingUpdateRequest;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.LignePicking;
import com.example.demo.entity.Picking;
import com.example.demo.entity.Rack;
import com.example.demo.entity.StatutLignePickingCode;
import com.example.demo.entity.StatutPickingCode;
import com.example.demo.entity.User;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.LignePickingRepository;
import com.example.demo.repository.PickingRepository;
import com.example.demo.repository.RackRepository;
import com.example.demo.repository.UserRepository;

@Service
public class PickingService {

    private static final List<StatutPickingCode> STATUTS_ACTIFS = List.of(
            StatutPickingCode.GENERE,
            StatutPickingCode.EN_COURS);

    private final PickingRepository pickingRepository;
    private final LignePickingRepository lignePickingRepository;
    private final JournalMouvementRepository journalMouvementRepository;
    private final UserRepository userRepository;
    private final RackRepository rackRepository;
    private final PickingStatutService pickingStatutService;
    private final LignePickingStatutService lignePickingStatutService;

    public PickingService(
            PickingRepository pickingRepository,
            LignePickingRepository lignePickingRepository,
            JournalMouvementRepository journalMouvementRepository,
            UserRepository userRepository,
            RackRepository rackRepository,
            PickingStatutService pickingStatutService,
            LignePickingStatutService lignePickingStatutService) {
        this.pickingRepository = pickingRepository;
        this.lignePickingRepository = lignePickingRepository;
        this.journalMouvementRepository = journalMouvementRepository;
        this.userRepository = userRepository;
        this.rackRepository = rackRepository;
        this.pickingStatutService = pickingStatutService;
        this.lignePickingStatutService = lignePickingStatutService;
    }

    @Transactional
    public PickingResponse create(PickingCreateRequest request) {
        if (request == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Les informations du picking sont obligatoires");
        }

        JournalMouvement journal = trouverJournal(request.journalId());
        verifierJournalSortie(journal);

        if (pickingRepository.existsByJournalMouvementIdAndStatutIn(journal.getId(), STATUTS_ACTIFS)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ce journal possede deja un picking actif");
        }

        User user = trouverUser(request.userId());
        Rack rackDepart = trouverRack(request.rackDepartId());

        Picking picking = pickingStatutService.creerPicking(journal, user, rackDepart);
        return versResponse(picking);
    }

    @Transactional(readOnly = true)
    public List<PickingResponse> findAll() {
        return pickingRepository.findAllByOrderByDateGenerationPickingDesc().stream()
                .map(this::versResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public PickingResponse findById(Long id) {
        return versResponse(trouverPicking(id));
    }

    @Transactional(readOnly = true)
    public List<PickingResponse> findAllByJournalId(Long journalId) {
        trouverJournal(journalId);
        return pickingRepository.findAllByJournalMouvementIdOrderByDateGenerationPickingDesc(journalId).stream()
                .map(this::versResponse)
                .toList();
    }

    @Transactional
    public PickingResponse update(Long id, PickingUpdateRequest request) {
        if (request == null || request.statut() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "L'utilisateur, le rack de depart et le statut sont obligatoires");
        }

        Picking picking = trouverPicking(id);
        User user = trouverUser(request.userId());
        Rack rackDepart = trouverRack(request.rackDepartId());

        boolean affectationModifiee = !Objects.equals(picking.getUser().getId(), user.getId())
                || !Objects.equals(picking.getRackDepart().getId(), rackDepart.getId());

        if (affectationModifiee && picking.getStatutCode() != StatutPickingCode.GENERE) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Un picking demarre ne peut plus changer d'utilisateur ou de rack de depart");
        }

        verifierTransition(picking.getStatutCode(), request.statut());

        picking.setUser(user);
        picking.setRackDepart(rackDepart);
        appliquerNouveauStatut(picking, request.statut());

        return versResponse(pickingRepository.save(picking));
    }

    @Transactional
    public void delete(Long id) {
        Picking picking = trouverPicking(id);

        if (lignePickingRepository.existsByPickingId(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ce picking contient des lignes et ne peut pas etre supprime");
        }

        pickingRepository.delete(picking);
    }

    private Picking trouverPicking(Long id) {
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "L'identifiant du picking est obligatoire");
        }
        return pickingRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Picking introuvable : " + id));
    }

    private JournalMouvement trouverJournal(Long id) {
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "L'identifiant du journal est obligatoire");
        }
        return journalMouvementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Journal introuvable : " + id));
    }

    private User trouverUser(Long id) {
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "L'identifiant de l'utilisateur est obligatoire");
        }
        return userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Utilisateur introuvable : " + id));
    }

    private Rack trouverRack(Long id) {
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "L'identifiant du rack de depart est obligatoire");
        }
        return rackRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Rack introuvable : " + id));
    }

    private void verifierJournalSortie(JournalMouvement journal) {
        String type = journal.getTypeMouvementJournal().getNomTypeMouvement();
        if (!"SORTIE".equalsIgnoreCase(type)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Un picking ne peut etre cree que pour un journal de sortie");
        }
    }

    private void verifierTransition(StatutPickingCode actuel, StatutPickingCode nouveau) {
        if (actuel == nouveau) {
            return;
        }

        boolean autorisee = switch (actuel) {
            case GENERE -> nouveau == StatutPickingCode.EN_COURS || nouveau == StatutPickingCode.ANNULE;
            case EN_COURS -> nouveau == StatutPickingCode.TERMINE || nouveau == StatutPickingCode.ANNULE;
            case TERMINE, ANNULE -> false;
        };

        if (!autorisee) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Transition de picking interdite : " + actuel + " vers " + nouveau);
        }
    }

    private void appliquerNouveauStatut(Picking picking, StatutPickingCode nouveauStatut) {
        if (picking.getStatutCode() == nouveauStatut) {
            return;
        }

        if (nouveauStatut == StatutPickingCode.EN_COURS && picking.getDateDebut() == null) {
            picking.setDateDebut(LocalDateTime.now());
        }

        if (nouveauStatut == StatutPickingCode.TERMINE) {
            boolean ligneNonTerminee = picking.getLignes().stream()
                    .map(LignePicking::getStatutCode)
                    .anyMatch(statut -> statut == StatutLignePickingCode.RESERVEE
                            || statut == StatutLignePickingCode.EN_COURS);

            if (ligneNonTerminee) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Toutes les lignes doivent etre terminees avant de terminer le picking");
            }
            picking.setDateFin(LocalDateTime.now());
        }

        if (nouveauStatut == StatutPickingCode.ANNULE) {
            for (LignePicking ligne : picking.getLignes()) {
                if (ligne.getStatutCode() == StatutLignePickingCode.RESERVEE
                        || ligne.getStatutCode() == StatutLignePickingCode.EN_COURS) {
                    lignePickingStatutService.changerStatut(ligne, StatutLignePickingCode.ANNULEE);
                }
            }
            picking.setDateFin(LocalDateTime.now());
        }

        pickingStatutService.changerStatut(picking, nouveauStatut);
    }

    private PickingResponse versResponse(Picking picking) {
        return new PickingResponse(
                picking.getId(),
                picking.getJournalMouvement().getId(),
                picking.getJournalMouvement().getReference(),
                picking.getUser().getId(),
                picking.getUser().getMatricule(),
                picking.getRackDepart().getId(),
                picking.getRackDepart().getNomRack(),
                picking.getDateGenerationPicking(),
                picking.getDateDebut(),
                picking.getDateFin(),
                picking.getStatutCode(),
                picking.getLignes().size());
    }

        
}
