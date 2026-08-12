package com.example.demo.entity;


import jakarta.persistence.Id;
import jakarta.persistence.*;
import java.util.List;

@Entity
@Table(name = "t_roles")
public class Role {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "nom_role", nullable = false, unique = true)
    private String name;
    
    @OneToMany(mappedBy = "role")
    private List<User> users;

    public Role() {
    }

    public Role(String name) {
        this.name = name;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
