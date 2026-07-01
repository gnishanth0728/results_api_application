package com.example.student.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

// DTO means Data transfer Object
// Purpose is never expose the entity directly to the client. It is used to transfer data between the client and the server. It is used to encapsulate the data and send it to the client. It is also used to receive data from the client and send it to the server.
//  It is like a package which contains the data and send it to the client. The entity is like a database table which contains the data and send it to the server.
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
