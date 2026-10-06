package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "t_notification")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "categorie", nullable = false, length = 40)
    private NotificationCategorie categorie;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 60)
    private NotificationType type;

    @Enumerated(EnumType.STRING)
    @Column(name = "priorite", nullable = false, length = 20)
    private NotificationPriorite priorite;

    @Column(name = "titre", nullable = false, length = 180)
    private String titre;

    @Column(name = "message", nullable = false, length = 1000)
    private String message;

    @Column(name = "date_creation", nullable = false)
    private LocalDateTime dateCreation;

    @Column(name = "date_lecture")
    private LocalDateTime dateLecture;

    @Column(name = "date_traitement")
    private LocalDateTime dateTraitement;

    @Column(name = "url_cible", length = 300)
    private String urlCible;

    @Column(name = "lu", nullable = false)
    private boolean lu = false;

    @Column(name = "traitee", nullable = false)
    private boolean traitee = false;

    @ManyToOne(optional = false)
    @JoinColumn(name = "destinataire_id", nullable = false)
    private User destinataire;

    @ManyToOne
    @JoinColumn(name = "journal_id")
    private JournalMouvement journal;

    @ManyToOne
    @JoinColumn(name = "detail_journal_id")
    private DetailJournal detailJournal;

    @ManyToOne
    @JoinColumn(name = "emplacement_id")
    private Emplacement emplacement;

    public Notification() {
    }

    public Notification(NotificationCategorie categorie, NotificationType type,
            NotificationPriorite priorite, String titre, String message,
            String urlCible, User destinataire) {
        this.categorie = categorie;
        this.type = type;
        this.priorite = priorite;
        this.titre = titre;
        this.message = message;
        this.urlCible = urlCible;
        this.destinataire = destinataire;
        this.dateCreation = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public NotificationCategorie getCategorie() { return categorie; }
    public void setCategorie(NotificationCategorie categorie) { this.categorie = categorie; }
    public NotificationType getType() { return type; }
    public void setType(NotificationType type) { this.type = type; }
    public NotificationPriorite getPriorite() { return priorite; }
    public void setPriorite(NotificationPriorite priorite) { this.priorite = priorite; }
    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public LocalDateTime getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDateTime dateCreation) { this.dateCreation = dateCreation; }
    public LocalDateTime getDateLecture() { return dateLecture; }
    public void setDateLecture(LocalDateTime dateLecture) { this.dateLecture = dateLecture; }
    public LocalDateTime getDateTraitement() { return dateTraitement; }
    public void setDateTraitement(LocalDateTime dateTraitement) { this.dateTraitement = dateTraitement; }
    public String getUrlCible() { return urlCible; }
    public void setUrlCible(String urlCible) { this.urlCible = urlCible; }
    public boolean isLu() { return lu; }
    public void setLu(boolean lu) { this.lu = lu; }
    public boolean isTraitee() { return traitee; }
    public void setTraitee(boolean traitee) { this.traitee = traitee; }
    public User getDestinataire() { return destinataire; }
    public void setDestinataire(User destinataire) { this.destinataire = destinataire; }
    public JournalMouvement getJournal() { return journal; }
    public void setJournal(JournalMouvement journal) { this.journal = journal; }
    public DetailJournal getDetailJournal() { return detailJournal; }
    public void setDetailJournal(DetailJournal detailJournal) { this.detailJournal = detailJournal; }
    public Emplacement getEmplacement() { return emplacement; }
    public void setEmplacement(Emplacement emplacement) { this.emplacement = emplacement; }
}
