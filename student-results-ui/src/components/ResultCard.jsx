import {
    Card,
    CardContent,
    Chip,
    Divider,
    Typography
} from "@mui/material";

import SubjectTable from "./SubjectTable";

export default function ResultCard({ student }) {

    if (!student) return null;

    return (

        <Card sx={{ mt: 4 }}>

            <CardContent>

                <Typography variant="h5">

                    {student.firstName} {student.lastName}

                </Typography>

                <Typography>

                    Roll Number : {student.rollNumber}

                </Typography>

                <Divider sx={{ my: 2 }} />

                <SubjectTable
                    subjects={student.subjects}
                />

                <Divider sx={{ my: 2 }} />

                <Typography>

                    Total : {student.total}

                </Typography>

                <Typography>

                    Percentage :
                    {student.percentage}

                </Typography>

                <Typography>

                    Grade :
                    {student.grade}

                </Typography>

                <Chip
                    color={
                        student.result === "PASS"
                            ? "success"
                            : "error"
                    }
                    label={student.result}
                />

            </CardContent>

        </Card>

    );

}
