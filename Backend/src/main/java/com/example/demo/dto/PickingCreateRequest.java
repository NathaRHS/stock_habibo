package com.example.demo.dto;

public record PickingCreateRequest(
        Long journalId,
        Long userId,
        Long rackDepartId) {
}
