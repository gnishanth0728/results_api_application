import axios from "axios";

// AXios converts the Javascript into an HTTP request.
const api = axios.create({
    baseURL: "http://34.229.154.246:8080"
});

export default api;
