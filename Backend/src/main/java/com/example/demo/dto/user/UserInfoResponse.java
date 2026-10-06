package com.example.demo.dto.user;

import java.util.List;

public record UserInfoResponse(String nom,
        String matricule,
        Long RoleId,
        String nomRole,List<UserNombreOperationDto> operations) {

}
