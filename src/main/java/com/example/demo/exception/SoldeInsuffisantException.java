package com.example.demo.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;

public class SoldeInsuffisantException extends RuntimeException {

    public SoldeInsuffisantException() {
        super("Solde insuffisant");
    }

    @ExceptionHandler(SoldeInsuffisantException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public String handleSoldeInsuffisant(
            SoldeInsuffisantException exception) {
        return exception.getMessage();
    }
}