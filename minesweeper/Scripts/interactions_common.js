/* Grupo: 38 */
/* Número: 64168, Nome: Daniel Santos, PL: 22 */
/* Número: 42081, Nome: Miguel Lopes, PL: 22 */

"use strict";

const LINK_SIGN_UP = "sign-up-ref";
const LINK_LOGIN = "login-ref"
const BUTTON_LOGOUT = "btn-logout";
const ITEM_LOGGED_USER = "loggedUser";

let loggedUser = null;

window.addEventListener("load", main);

function main() {
    loadLoggedUser();
    const signUpLink = document.getElementById(LINK_SIGN_UP);
    const loginLink = document.getElementById(LINK_LOGIN);
    const logoutButton = document.getElementById(BUTTON_LOGOUT);
    if (loggedUser) {
        signUpLink.classList.add("is-hidden");
        loginLink.classList.add("is-hidden");
        logoutButton.classList.remove("is-hidden");
        setupEventListeners();
    };
}

function setupEventListeners() {
    document.getElementById(BUTTON_LOGOUT).addEventListener("click", logout);
}

function logout() {
    localStorage.removeItem(ITEM_LOGGED_USER);
    location.reload();
}

function loadLoggedUser() {
    loggedUser = localStorage.getItem(ITEM_LOGGED_USER);
}
