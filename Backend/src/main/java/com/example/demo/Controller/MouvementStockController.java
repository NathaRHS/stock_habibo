package com.example.demo.Controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.MouvementStockResponse;
import com.example.demo.service.MouvementStockService;

@RestController
@RequestMapping("/mouvementStock")
public class MouvementStockController {
    @Autowired
    MouvementStockService mouvementStockService;

    @GetMapping
    public List<MouvementStockResponse> getMouvementStock() {
        return mouvementStockService.findAll();

    }
    @GetMapping("/entrees")
    public List<MouvementStockResponse> getAllEntry(){
        return mouvementStockService.getAllEntry();
    }
}
