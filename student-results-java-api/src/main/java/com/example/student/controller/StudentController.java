package com.example.student.controller;

import com.example.student.dto.StudentResponse;
import com.example.student.service.StudentService;
import org.springframework.web.bind.annotation.*;

// This is the controller class which receives the HTTP request, reads the URL, reads the path, validates the request, calls the service, and returns the JSON response.
// This main purpose is to route the request to the appropriate service and return the response. It does not contain any business logic. The business logic is in the service class.
// Think like a reception desk when visiting a hospital. The receptionist does not treat the patient, but she routes the patient to the appropriate doctor. The doctor is the one who treats the patient. Similarly, the controller is like a receptionist and the service is like a doctor.
@RestController
@RequestMapping("/students")
public class StudentController {

    private final StudentService service;

    public StudentController(StudentService service){

        this.service = service;

    }

    @GetMapping("/{rollNumber}")
    public StudentResponse getStudentResult(
            @PathVariable Long rollNumber){

        return service.getStudentResult(rollNumber);

    }

}
