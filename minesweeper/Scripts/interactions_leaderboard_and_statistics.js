/* Grupo: 38 */
/* Número: 64168, Nome: Daniel Santos, PL: 22 */
/* Número: 42081, Nome: Miguel Lopes, PL: 22 */

"use strict";

const PRELOGIN_CONTENT = "prelogin-content";
const STATS_CONTENT = "stats-content";
const DIFFICULTIES = [
    "beginner",
    "intermediate",
    "expert"
];
const ITEM_USERS = "users";

let currentUserGameHistory = null;
let users = [];

window.addEventListener("load", main);

function main() {
    const preLoginContent = document.getElementById(PRELOGIN_CONTENT);
    const statsContent = document.getElementById(STATS_CONTENT);
    if (loggedUser) {
        preLoginContent.classList.add("is-hidden");
        statsContent.classList.remove("is-hidden");
    };
    loadCurrentUserGameHistory();
    updateStatsTable();
    loadUsers();
    updateLeaderboardTable();
}

function updateStatsTable() {
    const statsTableRows = document.querySelectorAll(".stats-table")[0].rows;
    for (let idx = 0; idx < DIFFICULTIES.length; idx++) {
        const difficulty = DIFFICULTIES[idx];
        const userGameHistory = currentUserGameHistory.filter(function (game) {
            return game.difficulty === difficulty;
        });
        const gamesPlayed = userGameHistory.length;
        const gamesWon = userGameHistory.filter(function(game) {
            return game.win;
        }).length;
        let winPercentage = 0;
        if (gamesPlayed > 0) {
            winPercentage = ((gamesWon / gamesPlayed) * 100).toFixed(1);
        };
        const winElapsedTimes = userGameHistory.filter(function(game) {
            return game.win;
        }).map(function(game) {
            return Number(game.elapsedTime);
        });
        let bestTime;
        if (winElapsedTimes.length > 0) {
            bestTime = (Math.min.apply(null, winElapsedTimes)).toFixed(1);
        } else {
            bestTime = "-";
        };
        let averageTime;
        if (winElapsedTimes.length > 0) {
            let sum = 0;
            for (let index = 0; index < winElapsedTimes.length; index++) {
                sum += winElapsedTimes[index];
            };
            averageTime = (sum / winElapsedTimes.length).toFixed(1);
        } else {
            averageTime = "-";
        };
        statsTableRows[1].cells[idx + 1].textContent = gamesPlayed;
        statsTableRows[2].cells[idx + 1].textContent = gamesWon;
        statsTableRows[3].cells[idx + 1].textContent = winPercentage;
        statsTableRows[4].cells[idx + 1].textContent = bestTime;
        statsTableRows[5].cells[idx + 1].textContent = averageTime;
    };
}

function updateLeaderboardTable() {
    const leaderboardTableRows = document.querySelectorAll(".stats-table")[1].rows;
    const leaderboardEntriesByDifficulty = {
        beginner: [],
        intermediate: [],
        expert: []
    };
    for (let idx = 0; idx < users.length; idx++) {
        const user = users[idx];
        const storageKey = "game_history_" + user.username;
        const userGameHistory = JSON.parse(localStorage.getItem(storageKey)) || [];
        for (let index = 0; index < DIFFICULTIES.length; index++) {
            const difficulty = DIFFICULTIES[index];
            const winElapsedTimes = userGameHistory.filter(function(game) {
                return game.difficulty === difficulty && game.win;
            }).map(function(game) {
                return Number(game.elapsedTime);
            });
            if (winElapsedTimes.length > 0) {
                const bestTime = Math.min.apply(null, winElapsedTimes);
                leaderboardEntriesByDifficulty[difficulty].push({
                    username: user.username,
                    bestTime: bestTime
                });
            };
        };
    };
    for (let idx = 0; idx < DIFFICULTIES.length; idx++) {
        const difficulty = DIFFICULTIES[idx];
        leaderboardEntriesByDifficulty[difficulty].sort(function (firstEntry, secondEntry) {
            return firstEntry.bestTime - secondEntry.bestTime;
        });
    };
    const numLeaderboardEntries = 10;
    for (let idx = 0; idx < numLeaderboardEntries; idx++) {
        const row = leaderboardTableRows[3 + idx];
        for (let index = 0; index < DIFFICULTIES.length; index++) {
            const difficulty = DIFFICULTIES[index];
            const userEntry = leaderboardEntriesByDifficulty[difficulty][idx];
            const usernameCellIdx = 1 + (index * 2);
            const bestTimeCellIdx = 2 + (index * 2);
            if (userEntry) {
                row.cells[usernameCellIdx].textContent = userEntry.username;
                row.cells[bestTimeCellIdx].textContent = userEntry.bestTime.toFixed(1);
            } else {
                row.cells[usernameCellIdx].textContent = "-";
                row.cells[bestTimeCellIdx].textContent = "-";
            };
        };
    };
}

function loadCurrentUserGameHistory() {
    const storageKey = "game_history_" + loggedUser;
    currentUserGameHistory = JSON.parse(localStorage.getItem(storageKey)) || [];
}

function loadUsers() {
    users = JSON.parse(localStorage.getItem(ITEM_USERS)) || [];
}