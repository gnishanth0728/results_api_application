package com.example.student.service;

import com.example.student.dto.StudentResponse;
import com.example.student.dto.SubjectResponse;
import com.example.student.entity.Student;
import com.example.student.entity.StudentMark;
import com.example.student.repository.StudentMarksRepository;
import com.example.student.repository.StudentRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class StudentService {

    private final StudentRepository studentRepository;
    private final StudentMarksRepository marksRepository;

    public StudentService(StudentRepository studentRepository,
                          StudentMarksRepository marksRepository) {

        this.studentRepository = studentRepository;
        this.marksRepository = marksRepository;
    }

    public StudentResponse getStudentResult(Long rollNumber) {

        Student student = studentRepository.findById(rollNumber)
                .orElseThrow(() ->
                        new RuntimeException("Student not found"));

        List<StudentMark> marks =
                marksRepository.findByRollNumber(rollNumber);

        StudentResponse response =
                new StudentResponse();

        response.setRollNumber(student.getRollNumber());
        response.setFirstName(student.getFirstName());
        response.setLastName(student.getLastName());

        List<SubjectResponse> subjects =
                marks.stream()
                        .map(m -> new SubjectResponse(
                                m.getSubjectName(),
                                m.getMarks()))
                        .toList();

        response.setSubjects(subjects);

        int total = marks.stream()
          .mapToInt(StudentMark::getMarks)
          .sum();

        double percentage = total / 6.0;

        response.setTotal(total);
        response.setPercentage(percentage);
        response.setGrade(getGrade(percentage));

        boolean pass = marks.stream()
                .allMatch(mark -> mark.getMarks() >= 35);

        response.setResult(pass ? "PASS" : "FAIL");

        return response;
    }

    private String getGrade(double percentage){

        if(percentage>=90)
            return "A+";

        if(percentage>=80)
            return "A";

        if(percentage>=70)
            return "B";

        if(percentage>=60)
            return "C";

        return "F";
    }

}
