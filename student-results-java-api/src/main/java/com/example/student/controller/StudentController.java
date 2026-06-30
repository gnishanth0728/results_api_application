package com.example.student.controller;

import com.example.student.dto.StudentResponse;
import com.example.student.service.StudentService;
import org.springframework.web.bind.annotation.*;

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
