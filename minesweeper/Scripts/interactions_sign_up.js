/* Grupo: 38 */
/* Número: 64168, Nome: Daniel Santos, PL: 22 */
/* Número: 42081, Nome: Miguel Lopes, PL: 22 */

"use strict";

const FORM_SIGN_UP = "frm-sign-up";
const USERNAME = "username";
const EMAIL = "email";
const DATE_OF_BIRTH = "date-of-birth";
const PASSWORD = "password";
const AVATAR = "avatar";
const BUTTON_SIGN_UP = "btn-sign-up";
const ITEM_USERS = "users";

let formSignUp = null;
let avatarImages = [];
let users = [];

function User(username, email, dateOfBirth, password, avatar) {
    this.username = username;
    this.email = email;
    this.dateOfBirth = dateOfBirth;
    this.password = password;
    this.avatar = avatar;
}

window.addEventListener("load", main);

function main() {
    formSignUp = document.forms[FORM_SIGN_UP];
    avatarImages = document.querySelectorAll("#avatar-img img");
    loadUsers();
    setupEventListeners();
}

function setupEventListeners() {
    const avatarInputField = formSignUp.elements[AVATAR];
    avatarImages.forEach(function(avatarImage) {
        avatarImage.addEventListener("click", function() {
            avatarImages.forEach(function(avatarImage) {
                avatarImage.classList.remove("avatar-img-selected");
            });
            avatarImage.classList.add("avatar-img-selected");
            avatarInputField.value = avatarImage.dataset.avatar;
        });
    });
    document.getElementById(BUTTON_SIGN_UP).addEventListener("click", signUp);
}

function signUp() {
    const validSignUp = formSignUp.reportValidity();
    if (!validSignUp) {
        return;
    };
    if (!formSignUp.elements[AVATAR].value) {
        alert("Hey, don't forget to pick your avatar! You gotta look the part.");
        return;
    };
    const username = formSignUp.elements[USERNAME].value;
    const isUsernameTaken = users.some(function(user) {
        return user.username.toLowerCase() === username.toLowerCase();
    });
    if (isUsernameTaken) {
        alert("Oops! That username's taken. How about trying a different one?");
        return;
    };
    const email = formSignUp.elements[EMAIL].value;
    const isEmailTaken = users.some(function(user) {
        return user.email.toLowerCase() === email.toLowerCase();
    });
    if (isEmailTaken) {
        alert("Looks like this email's already in use. Try a different one.");
        return;
    };
    const user = getUserInfo();
    saveUser(user);
    formSignUp.reset();
    formSignUp.elements[AVATAR].value = "";
    avatarImages.forEach(function(avatarImage) {
        avatarImage.classList.remove("avatar-img-selected");
    });
    alert("Boom! You're signed up. Ready to log in and start sweeping mines?");
}

function getUserInfo() {
    return new User(
        formSignUp.elements[USERNAME].value, 
        formSignUp.elements[EMAIL].value, 
        formSignUp.elements[DATE_OF_BIRTH].value, 
        formSignUp.elements[PASSWORD].value, 
        formSignUp.elements[AVATAR].value
    );
}

function loadUsers() {
    users = JSON.parse(localStorage.getItem(ITEM_USERS)) || [];
}

function storeUsers() {
    localStorage.setItem(ITEM_USERS, JSON.stringify(users));
}

function saveUser(user) {
    users.push(user);
    storeUsers();
}