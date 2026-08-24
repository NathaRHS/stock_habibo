package com.example.demo.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.demo.dto.MouvementStockResponse;
import com.example.demo.entity.MouvementStock;
import com.example.demo.entity.TypeMouvementStock;
import com.example.demo.repository.MouvementStockRepository;

@Service
public class MouvementStockService {
    @Autowired
    MouvementStockRepository mouvementStockRepo;

    public List<MouvementStockResponse> findAll() {
        return mouvementStockRepo.findAll().stream().map(this::versResponse).toList();
    }

    private MouvementStockResponse versResponse(MouvementStock mouvementStock) {
        TypeMouvementStock type = mouvementStock.getTypeMouvement();
 return new MouvementStockResponse(
        type.getId(),
        type.getNomTypeMouvement(),
        type.getSens(),
        mouvementStock.getQuantitePiecesReelle(),
        mouvementStock.getDateMouvement()
    );    }

    public List<MouvementStockResponse> getAllEntry() {
      return mouvementStockRepo.getAllEntry().stream().map(this::versResponse).toList();
    }
}
