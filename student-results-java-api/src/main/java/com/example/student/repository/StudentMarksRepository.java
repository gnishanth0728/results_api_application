package com.example.student.repository;

import com.example.student.entity.StudentMark;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

// Respository class which is used to interact with the database. It contains methods to perform CRUD operations on the StudentMark entity. It extends JpaRepository which provides methods to perform CRUD operations on the database. It also contains a custom method to find the marks of a student by roll number.
// It read the database ,save data to the database,update data in the database and delete data from the database. It is used by the service class to perform CRUD operations on the StudentMark entity.
// Respository never know the HTTP, json and browser. It is only responsible for interacting with the database. It is like a database clerk who is responsible for maintaining the records in the database. The service class is like a doctor who is responsible for treating the patient. The controller class is like a receptionist who is responsible for routing the patient to the appropriate doctor.
public interface StudentMarksRepository
        extends JpaRepository<StudentMark,Long> {

    List<StudentMark> findByRollNumber(Long rollNumber);

}
