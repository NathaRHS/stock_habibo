package com.example.demo.dto.picking;

import com.example.demo.entity.StatutPicking;

public record PickingUpdateRequest(
        Long userId,
        Long rackDepartId,
        StatutPicking statut) {
}
