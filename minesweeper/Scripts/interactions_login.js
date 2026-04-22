/* Grupo: 38 */
/* Número: 64168, Nome: Daniel Santos, PL: 22 */
/* Número: 42081, Nome: Miguel Lopes, PL: 22 */

"use strict";

const FORM_LOGIN = "frm-login";
const EMAIL = "email";
const PASSWORD = "password";
const BUTTON_LOGIN = "btn-login";
const ITEM_USERS ="users";
const ITEM_LOGGED_USER = "loggedUser";

let formLogin = null;
let users = [];

window.addEventListener("load", main);

function main() {
    formLogin = document.forms[FORM_LOGIN];
    loadUsers();
    setupEventListeners();
}

function setupEventListeners() {
    document.getElementById(BUTTON_LOGIN).addEventListener("click", login);
}

function login() {
    const validLogin = formLogin.reportValidity();
    if (!validLogin) {
        return;
    };
    const email = formLogin.elements[EMAIL].value;
    const password = formLogin.elements[PASSWORD].value;
    const userFound = users.find(function(user) {
        return user.email.toLowerCase() === email.toLowerCase() && 
               user.password === password;
    });
    if (userFound) {
        storeLoggedUser(userFound);
        alert("Safe click! Login cleared. Time to sweep some mines!");
        window.location.href = "Minesweeper_Main_Page.html";
    } else {
        alert("Uh-oh! That email or password doesn't match our records.")
    };
}

function loadUsers() {
    users = JSON.parse(localStorage.getItem(ITEM_USERS)) || [];
}

function storeLoggedUser(user) {
    localStorage.setItem(ITEM_LOGGED_USER, user.username);
}