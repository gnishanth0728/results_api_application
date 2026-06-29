import axios from "axios";

const api = axios.create({
    baseURL: "http://50.17.121.255:8080"
});

export default api;
