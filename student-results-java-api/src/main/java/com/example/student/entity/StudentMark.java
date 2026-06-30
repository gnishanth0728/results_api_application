package com.example.student.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "student_marks")
@Getter
@Setter
@NoArgsConstructor
public class StudentMark {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name="roll_number")
    private Long rollNumber;

    @Column(name="subject_name")
    private String subjectName;

    private Integer marks;
}
