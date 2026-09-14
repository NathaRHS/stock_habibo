package com.example.demo.projection;


import java.time.LocalDate;
import java.time.LocalDateTime;

public interface StockProjection {

    Long getArticleId();

    Long getEmplacementId();

    Integer getQuantiteStock();

    LocalDate getDlc();

    LocalDateTime getDateMouvement();
}