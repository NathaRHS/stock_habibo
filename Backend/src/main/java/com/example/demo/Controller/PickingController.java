package com.example.demo.Controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.dto.picking.PickingCreateRequest;
import com.example.demo.dto.picking.PickingResponse;
import com.example.demo.dto.picking.PickingUpdateRequest;
import com.example.demo.service.PickingService;

@RestController
@RequestMapping("/pickings")
public class PickingController {

    private final PickingService pickingService;

    public PickingController(PickingService pickingService) {
        this.pickingService = pickingService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PickingResponse create(@RequestBody PickingCreateRequest request) {
        return pickingService.create(request);
    }

    @GetMapping
    public List<PickingResponse> findAll() {
        return pickingService.findAll();
    }

    @GetMapping("/{id}")
    public PickingResponse findById(@PathVariable Long id) {
        return pickingService.findById(id);
    }

    @GetMapping("/journal/{journalId}")
    public List<PickingResponse> findAllByJournalId(@PathVariable Long journalId) {
        return pickingService.findAllByJournalId(journalId);
    }

    @PutMapping("/{id}")
    public PickingResponse update(
            @PathVariable Long id,
            @RequestBody PickingUpdateRequest request) {
        return pickingService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        pickingService.delete(id);
    }
}
