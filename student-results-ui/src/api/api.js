import axios from "axios";

const api = axios.create({
    baseURL: "http://54.123.45.67:8080"
});

export default api;
