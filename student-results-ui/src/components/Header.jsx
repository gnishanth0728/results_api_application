import { AppBar, Toolbar, Typography } from "@mui/material";
import SchoolIcon from "@mui/icons-material/School";

export default function Header() {
    return (
        <AppBar position="static">
            <Toolbar>
                <SchoolIcon sx={{ mr: 2 }} />
                <Typography variant="h6">
                    Student Results Portal
                </Typography>
            </Toolbar>
        </AppBar>
    );
}
