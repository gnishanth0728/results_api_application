package com.example.student.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class StudentResponse {

    private Long rollNumber;

    private String firstName;

    private String lastName;

    private List<SubjectResponse> subjects;

    private Integer total;

    private Double percentage;

    private String grade;

    private String result;

}
