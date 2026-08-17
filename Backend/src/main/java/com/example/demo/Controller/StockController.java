package com.example.demo.Controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.StockParEtageResponse;
import com.example.demo.service.StockService;

@RestController
@RequestMapping("/stocks")
public class StockController {
    private final StockService stockService;

    public StockController(StockService stockService) {
        this.stockService = stockService;
    }

    @GetMapping("/etages")
    public List<StockParEtageResponse> showAllStocksParEtage() {
        return stockService.getAllStocksParEtage();
    }

    @GetMapping("/articles/{articleId}/etages")
    public List<StockParEtageResponse> showStocksParEtageByArticleId(
            @PathVariable Long articleId) {
        return stockService.getStocksParEtageByArticleId(articleId);
    }
}
