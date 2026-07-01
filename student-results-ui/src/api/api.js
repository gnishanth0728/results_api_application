import axios from "axios";

// AXios converts the Javascript into an HTTP request.
const api = axios.create({
    baseURL: "http://50.17.121.255:8080"
});

export default api;
