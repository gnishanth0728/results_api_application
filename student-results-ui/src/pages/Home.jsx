import { Container } from "@mui/material";
import { useState } from "react";

import api from "../api/api";

import Header from "../components/Header";
import SearchForm from "../components/SearchForm";
import ResultCard from "../components/ResultCard";

export default function Home() {

    const [student, setStudent] = useState(null);

    async function search(rollNumber) {

        const response =
            await api.get("/students/" + rollNumber);

        setStudent(response.data);

    }

    return (

        <>
            <Header />

            <Container>

                <SearchForm
                    onSearch={search}
                />

                <ResultCard
                    student={student}
                />

            </Container>

        </>

    );

}
