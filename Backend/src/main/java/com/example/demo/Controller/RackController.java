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

import com.example.demo.dto.RackRequest;
import com.example.demo.dto.RackResponse;
import com.example.demo.service.RackService;

@RestController
@RequestMapping("/rack")
public class RackController {
    private final RackService rackService;

    public RackController(RackService rackService) {
        this.rackService = rackService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RackResponse create(@RequestBody RackRequest request) {
        return rackService.create(request);
    }

    @GetMapping
    public List<RackResponse> findAll() {
        return rackService.findAll();
    }

    @GetMapping("/{id}")
    public RackResponse findById(@PathVariable Long id) {
        return rackService.findById(id);
    }

    @PutMapping("/{id}")
    public RackResponse update(@PathVariable Long id, @RequestBody RackRequest request) {
        return rackService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        rackService.delete(id);
    }
}
