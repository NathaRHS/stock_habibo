package com.example.demo.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record DetailPrelevementResponse(
    Long prelevementId,
    String nomRack,
    String nomEmplacement,
    Integer quantitePrelevee,
    LocalDate dlc,
    LocalDate dlv,
    LocalDateTime dateScan
) {}