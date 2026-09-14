package com.example.demo.dto;

import java.util.List;

public record CommandeAllRequest(List<CommandeCreateRequest>commandes) {
    
}
