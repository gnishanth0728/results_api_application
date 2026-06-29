import { Alert, CircularProgress, Container } from "@mui/material";
import { useState } from "react";

import api from "../api/api";

import Header from "../components/Header";
import SearchForm from "../components/SearchForm";
import ResultCard from "../components/ResultCard";

export default function Home() {

    const [student, setStudent] = useState(null);
    const [error, setError] = useState("");
    const [loading, setLoading] = useState(false);

    async function search(rollNumber) {

        setLoading(true);
        setError("");
        setStudent(null);

        try {

            const response = await api.get("/students/" + rollNumber);

            setStudent(response.data);

        } catch (err) {

            if (err.response) {

                setError(err.response.data.message);

            } else {

                setError("Unable to connect to the server.");

            }

        } finally {

            setLoading(false);

        }

    }

    return (

        <>
            <Header />

            <Container maxWidth="md" sx={{ mt: 4 }}>

                <SearchForm onSearch={search} />

                {loading && (
                    <CircularProgress sx={{ mt: 4 }} />
                )}

                {error && (
                    <Alert severity="error" sx={{ mt: 4 }}>
                        {error}
                    </Alert>
                )}

                {!loading && student && (
                    <ResultCard student={student} />
                )}

            </Container>

        </>

    );

}
