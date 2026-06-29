import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableRow
} from "@mui/material";

export default function SubjectTable({ subjects }) {

    return (

        <Table>

            <TableHead>

                <TableRow>

                    <TableCell>Subject</TableCell>

                    <TableCell>Marks</TableCell>

                </TableRow>

            </TableHead>

            <TableBody>

                {subjects.map((subject) => (

                    <TableRow key={subject.subject}>

                        <TableCell>
                            {subject.subject}
                        </TableCell>

                        <TableCell>
                            {subject.marks}
                        </TableCell>

                    </TableRow>

                ))}

            </TableBody>

        </Table>

    );

}
