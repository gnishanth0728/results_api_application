import { Button, Paper, Stack, TextField } from "@mui/material";
import { useState } from "react";

export default function SearchForm({ onSearch }) {

    const [rollNumber, setRollNumber] = useState("");

    return (
        <Paper sx={{ p: 4, mt: 4 }}>

            <Stack spacing={2}>

                <TextField
                    label="Roll Number"
                    value={rollNumber}
                    onChange={(e) =>
                        setRollNumber(e.target.value)}
                />

                <Button
                    variant="contained"
                    onClick={() => onSearch(rollNumber)}
                >
                    Get Result
                </Button>

            </Stack>

        </Paper>
    );
}
