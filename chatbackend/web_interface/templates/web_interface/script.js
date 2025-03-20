// script.js
const chatWindow = document.getElementById('chat-window');
const messageInput = document.getElementById('message-input');
const sendButton = document.getElementById('send-button');

// Function to add a message to the chat window
function addMessage(sender, message) {
    const messageElement = document.createElement('div');
    messageElement.classList.add('message', sender);
    messageElement.innerHTML = `<p>${message}</p>`;
    chatWindow.appendChild(messageElement);
    chatWindow.scrollTop = chatWindow.scrollHeight; // Auto-scroll to bottom
}

// Function to send a message
function sendMessage() {
    const userMessage = messageInput.value.trim();
    if (!userMessage) return;

    // Add user message to chat window
    addMessage('user', userMessage);
    messageInput.value = ''; // Clear input field

    // Simulate AI response (replace with actual API call later)
    setTimeout(() => {
        addMessage('ai', 'This is a simulated AI response.');
    }, 1000);
}

// Event listeners
sendButton.addEventListener('click', sendMessage);
messageInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        sendMessage();
    }
});