const express = require('express');
const path = require('path');
const app = express();
const port = 8000;

// Serve static files from the "admin_web" directory
app.use(express.static(path.join(__dirname, 'chatbackend', 'admin_web')));

// Define a route to serve the login page
app.get('/admin_web/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'chatbackend', 'admin_web', 'templates', 'admin_web', 'login.html'));
});

// Define a route to serve the dashboard page
app.get('/admin_web/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'chatbackend', 'admin_web', 'templates', 'admin_web', 'dashboard.html'));
});

// Start the server
app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});
