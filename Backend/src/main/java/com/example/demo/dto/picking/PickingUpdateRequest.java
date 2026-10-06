package com.example.demo.dto.picking;

import com.example.demo.entity.StatutPickingCode;

public record PickingUpdateRequest(
        Long userId,
        Long rackDepartId,
        StatutPickingCode statut) {
}
