package com.example.student.repository;

import com.example.student.entity.StudentMark;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StudentMarksRepository
        extends JpaRepository<StudentMark,Long> {

    List<StudentMark> findByRollNumber(Long rollNumber);

}
