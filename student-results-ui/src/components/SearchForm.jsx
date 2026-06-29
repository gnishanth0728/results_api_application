import { Button, Paper, Stack, TextField } from "@mui/material";
import { useState } from "react";

export default function SearchForm({ onSearch }) {

    const [rollNumber, setRollNumber] = useState("");
    const [error, setError] = useState("");

    const search = () => {

        if (rollNumber.trim() === "") {
            setError("Roll Number is required");
            return;
        }

        if (!/^\d{10}$/.test(rollNumber)) {
            setError("Roll Number must be 10 digits");
            return;
        }

        setError("");
        onSearch(rollNumber);
    };

    return (

        <Paper sx={{ p: 4, mt: 4 }}>

            <Stack spacing={2}>

                <TextField
                    label="Roll Number"
                    value={rollNumber}
                    error={!!error}
                    helperText={error}
                    onChange={(e) => {

                        const value = e.target.value;

                        // Allow only digits
                        if (/^\d*$/.test(value)) {
                            setRollNumber(value);
                        }

                    }}
                    onKeyDown={(e) => {
                        if (e.key === "Enter") {
                            search();
                        }
                    }}
                />

                <Button
                    variant="contained"
                    onClick={search}
                    disabled={rollNumber.length !== 10}
                >
                    Get Result
                </Button>

            </Stack>

        </Paper>

    );
}
