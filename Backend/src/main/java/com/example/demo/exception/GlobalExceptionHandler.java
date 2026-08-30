package com.example.demo.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ObjectOptimisticLockingFailureException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public String handleOptimisticLock(
            ObjectOptimisticLockingFailureException exception) {
        return "Le compte a été modifié par une autre opération. Réessayez.";
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ProblemDetail> gererResponseStatusException(
            ResponseStatusException exception) {

        ProblemDetail probleme = ProblemDetail.forStatusAndDetail(
                exception.getStatusCode(),
                exception.getReason());

        return ResponseEntity
                .status(exception.getStatusCode())
                .body(probleme);
    }
}