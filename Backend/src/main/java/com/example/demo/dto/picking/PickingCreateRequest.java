package com.example.demo.dto.picking;

public record PickingCreateRequest(
        Long journalId,
        Long userId,
        Long rackDepartId) {
}
