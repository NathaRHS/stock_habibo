package com.example.demo.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.StockParEmplacementResponse;
import com.example.demo.service.StockService;

@RestController
@RequestMapping("/stocks")
public class StockController {
    private final StockService stockService;

    public StockController(StockService stockService) {
        this.stockService = stockService;
    }

    @GetMapping("/emplacements")
    public List<StockParEmplacementResponse> showAllStocksParEmplacement() {
        return stockService.getAllStocksParEmplacement();
    }

    // @GetMapping("/getListeEmplacementTotal")
    

    @GetMapping("/articles/{articleId}/emplacements")
    public List<StockParEmplacementResponse> showStocksParEmplacementByArticleId(
            @PathVariable Long articleId) {
        return stockService.getStocksParEmplacementByArticleId(articleId);
    }
}
