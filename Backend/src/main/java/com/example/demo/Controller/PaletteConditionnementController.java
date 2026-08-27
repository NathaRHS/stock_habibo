package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.CreatePaletteConditionnementRequest;
import com.example.demo.dto.PaletteConditionnementResponse;
import com.example.demo.service.PaletteConditionnementService;

@RestController
@RequestMapping("/palettes-conditionnements")
public class PaletteConditionnementController {
    private final PaletteConditionnementService paletteConditionnementService;

    public PaletteConditionnementController(
            PaletteConditionnementService paletteConditionnementService) {
        this.paletteConditionnementService = paletteConditionnementService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PaletteConditionnementResponse create(
            @RequestBody CreatePaletteConditionnementRequest request) {
        return paletteConditionnementService.create(request);
    }

    @GetMapping
    public List<PaletteConditionnementResponse> findAll() {
        return paletteConditionnementService.findAll();
    }

    @GetMapping("/{id}")
    public PaletteConditionnementResponse findById(@PathVariable Long id) {
        return paletteConditionnementService.findById(id);
    }
}
