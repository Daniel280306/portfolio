/* Grupo: 38 */
/* Número: 64168, Nome: Daniel Santos, PL: 22 */
/* Número: 42081, Nome: Miguel Lopes, PL: 22 */

"use strict";

const PRELOGIN_CONTENT = "prelogin-content";
const GAME_CONTENT = "game-content";
const DIFFICULTY_BUTTONS = [
    {id: "btn-diff-beginner", difficulty: "beginner"},
    {id: "btn-diff-intermediate", difficulty: "intermediate"},
    {id: "btn-diff-expert", difficulty: "expert"}
];
const DIFFICULTY_SETTINGS = {
    beginner: {rows: 9, columns: 9, numMines: 10, maxGameDuration: 120},
    intermediate: {rows: 16, columns: 16, numMines: 40, maxGameDuration: 420},
    expert: {rows: 30, columns: 16, numMines: 99, maxGameDuration: 720}
};
const GAME_TABLE = "game-table";
const BUTTON_START_GAME = "btn-start-game";
const BUTTON_END_GAME = "btn-end-game";
const BUTTON_RESTART_GAME = "btn-restart-game";
const SPAN_MINES_LEFT = "span-mines-left";
const SPAN_TIME_ELAPSED = "span-time-elapsed";
const SPAN_REMAINING_TIME = "span-remaining-time";

let game = {}
let timerElapsedTime = null;
let timerRemainingTime = null;

window.addEventListener("load", main);

function main() {
    const preLoginContent = document.getElementById(PRELOGIN_CONTENT);
    const gameContent = document.getElementById(GAME_CONTENT);
    if (loggedUser) {
        preLoginContent.classList.add("is-hidden");
        gameContent.classList.remove("is-hidden");
    };
    document.getElementById(BUTTON_END_GAME).disabled = true;
    document.getElementById(BUTTON_RESTART_GAME).disabled = true;
    setupEventListenersGame();
    setDifficulty("beginner");
    const defaultButton = DIFFICULTY_BUTTONS.find(function(buttonInfo) {
        return buttonInfo.difficulty === "beginner";
    });
    document.getElementById(defaultButton.id).classList.add("btn-diff-selected");
}

function setupEventListenersGame() {
    DIFFICULTY_BUTTONS.forEach(function(buttonInfo) {
        let button = document.getElementById(buttonInfo.id);
        button.addEventListener("click", function() {
            DIFFICULTY_BUTTONS.forEach(function(buttonInfo) {
                let button = document.getElementById(buttonInfo.id);
                button.classList.remove("btn-diff-selected");
            });
            button.classList.add("btn-diff-selected");
            setDifficulty(buttonInfo.difficulty);
        });
    });
    document.getElementById(BUTTON_START_GAME).addEventListener("click", startGame);
    document.getElementById(BUTTON_END_GAME).addEventListener("click", function() {
        endGame(false, false, true)
    });
    document.getElementById(BUTTON_RESTART_GAME).addEventListener("click", restartGame);
}

function setDifficulty(difficulty) {
    const settings = DIFFICULTY_SETTINGS[difficulty];
    game = {
        difficulty: difficulty,
        rows: settings.rows,
        columns: settings.columns,
        numMines: settings.numMines,
        maxGameDuration: settings.maxGameDuration,
        board: [],
        revealedCells: [],
        flaggedCells: [],
        mineCells: [],
        isActive: false,
        firstClick: true,
        startTime: null
    };
    initializeGameArrays();
    createEmptyGameTable(settings.rows, settings.columns);
    document.getElementById(BUTTON_START_GAME).disabled = false;
    document.getElementById(BUTTON_END_GAME).disabled = true;
    document.getElementById(BUTTON_RESTART_GAME).disabled = true;
    document.getElementById(SPAN_MINES_LEFT).textContent = game.numMines;
    document.getElementById(SPAN_TIME_ELAPSED).textContent = "0";
    document.getElementById(SPAN_REMAINING_TIME).textContent = "0";
}

function initializeGameArrays() {
    game.board = Array.from({length: game.rows}, function() {
        return new Array(game.columns).fill(0);
    });
    game.revealedCells = Array.from({length: game.rows}, function() {
        return new Array(game.columns).fill(false);
    });
    game.flaggedCells = Array.from({length: game.rows}, function() {
        return new Array(game.columns).fill(false);
    });
    game.mineCells = Array.from({length: game.rows}, function() {
        return new Array(game.columns).fill(false);
    });
}

function createEmptyGameTable(rows, columns) {
    const gameTable = document.getElementById(GAME_TABLE);
    gameTable.innerHTML = "";
    for (let rowIdx = 0; rowIdx < rows; rowIdx++) {
        let tableRow = document.createElement("tr");
        for (let columnIdx = 0; columnIdx < columns; columnIdx++) {
            let tableCell = document.createElement("td");
            tableCell.dataset.rowIdx = rowIdx;
            tableCell.dataset.columnIdx = columnIdx;
            tableCell.onclick = function() {
                handleLeftClick(tableCell);
            };
            tableCell.oncontextmenu = function(event) {
                event.preventDefault();
                handleRightClick(tableCell);
            };
            tableRow.appendChild(tableCell);
        };
        gameTable.appendChild(tableRow);
    };
}

function handleLeftClick(cell) {
    const rowIdx = parseInt(cell.dataset.rowIdx);
    const columnIdx = parseInt(cell.dataset.columnIdx);
    if (!game.isActive || game.flaggedCells[rowIdx][columnIdx]) {
        return;
    };
    if (game.firstClick) {
        placeMines(rowIdx, columnIdx);
        calculateAdjacentMines();
        game.isActive = true;
        game.firstClick = false;
    };
    if (game.mineCells[rowIdx][columnIdx]) {
        cell.textContent = "💣";
        endGame(false);
    } else {
        revealCell(rowIdx, columnIdx);
        checkForWin();
    };
}

function handleRightClick(cell) {
    const rowIdx = parseInt(cell.dataset.rowIdx);
    const columnIdx = parseInt(cell.dataset.columnIdx);
    if (!game.isActive) {
        return;
    };
    if (game.revealedCells[rowIdx][columnIdx]) {
        return;
    };
    if (game.flaggedCells[rowIdx][columnIdx]) {
        cell.textContent = "";
        game.flaggedCells[rowIdx][columnIdx] = false;
    } else {
        cell.textContent = "🚩";
        game.flaggedCells[rowIdx][columnIdx] = true;
    };
    showMinesLeft();
    checkForWin();
}

function placeMines(firstClickRow, firstClickColumn) {
    let minesPlaced = 0;
    game.mineCells = Array.from({length: game.rows}, function() {
        return new Array(game.columns).fill(false);
    });
    while (minesPlaced < game.numMines) {
        const randRow = Math.floor(Math.random() * game.rows);
        const randColumn = Math.floor(Math.random() * game.columns);
        const nearFirstClick = (randRow >= firstClickRow - 1 && randRow <= firstClickRow + 1) &&
                               (randColumn >= firstClickColumn - 1 && randColumn <= firstClickColumn + 1);
        if (!nearFirstClick && !game.mineCells[randRow][randColumn]) {
            game.mineCells[randRow][randColumn] = true;
            minesPlaced++;
        };
    };
}

function calculateAdjacentMines() {
    for (let rowIdx = 0; rowIdx < game.rows; rowIdx++) {
        for (let columnIdx = 0; columnIdx < game.columns; columnIdx++) {
            if (game.mineCells[rowIdx][columnIdx]) {
                continue;
            };
            let adjacentMines = 0;
            for (let deltaRow = -1; deltaRow <= 1; deltaRow++) {
                for (let deltaColumn = -1; deltaColumn <= 1; deltaColumn++) {
                    if (deltaRow === 0 && deltaColumn === 0) {
                        continue;
                    };
                    const adjacentRow = rowIdx + deltaRow;
                    const adjacentColumn = columnIdx + deltaColumn;
                    const insideBoard = (adjacentRow >= 0 && adjacentRow < game.rows) &&
                                        (adjacentColumn >= 0 && adjacentColumn < game.columns);
                    if (insideBoard && game.mineCells[adjacentRow][adjacentColumn]) {
                        adjacentMines++;
                    };
                };
            };
            game.board[rowIdx][columnIdx] = adjacentMines;
        };
    };
}

function revealCell(rowIdx, columnIdx) {
    if (rowIdx < 0 || rowIdx >= game.rows || columnIdx < 0 || columnIdx >= game.columns) {
        return;
    };
    if (game.revealedCells[rowIdx][columnIdx] || game.flaggedCells[rowIdx][columnIdx]) {
        return;
    };
    game.revealedCells[rowIdx][columnIdx] = true;
    const cell = document.querySelector(`td[data-row-idx="${rowIdx}"][data-column-idx="${columnIdx}"]`);
    if (!cell) {
        return;
    };
    cell.classList.add("revealed-cell");
    const adjacentMines = game.board[rowIdx][columnIdx];
    if (adjacentMines > 0) {
        cell.textContent = adjacentMines;
        cell.setAttribute("data-adjacent-mines", adjacentMines);
    } else {
        cell.textContent = "";
        cell.removeAttribute("data-adjacent-mines", adjacentMines);
        for (let deltaRow = -1; deltaRow <= 1; deltaRow++) {
            for (let deltaColumn = -1; deltaColumn <= 1; deltaColumn++) {
                if (deltaRow === 0 && deltaColumn === 0) {
                    continue;
                };
                revealCell(rowIdx + deltaRow, columnIdx + deltaColumn);
            };
        };
    };
}

function checkForWin() {
    let allNonMineCellsRevealed = true;
    let correctlyFlaggedMines = 0;
    for (let rowIdx = 0; rowIdx < game.rows; rowIdx++) {
        for (let columnIdx = 0; columnIdx < game.columns; columnIdx++) {
            if (!game.mineCells[rowIdx][columnIdx] && !game.revealedCells[rowIdx][columnIdx]) {
                allNonMineCellsRevealed = false;
            };
            if (game.flaggedCells[rowIdx][columnIdx]) {
                if (game.mineCells[rowIdx][columnIdx]) {
                    correctlyFlaggedMines++;
                } else {
                    correctlyFlaggedMines = -Infinity;
                };
            };
        };
    };
    if (allNonMineCellsRevealed || correctlyFlaggedMines === game.numMines) {
        endGame(true);
    };
}

function revealAllMines() {
    for (let rowIdx = 0; rowIdx < game.rows; rowIdx++) {
        for (let columnIdx = 0; columnIdx < game.columns; columnIdx++) {
            if (game.mineCells[rowIdx][columnIdx]) {
                const cell = document.querySelector(`td[data-row-idx="${rowIdx}"][data-column-idx="${columnIdx}"]`);
                if (cell) {
                    cell.textContent = "💣";
                    cell.classList.add("revealed-bomb");
                };
            };
        };
    };
}

function startGame() {
    if (game.isActive) {
        return;
    };
    document.getElementById(BUTTON_START_GAME).disabled = true;
    document.getElementById(BUTTON_END_GAME).disabled = false;
    game.isActive = true;
    game.startTime = Date.now();
    showElapsedTime();
    showRemainingTime();
    timerElapsedTime = setInterval(showElapsedTime, 1000);
    timerRemainingTime = setInterval(showRemainingTime, 1000);
}

function endGame(wasWin = false, wasTimeout = false, wasManual = false) {
    if (!game.isActive) {
        return;
    };
    document.getElementById(BUTTON_END_GAME).disabled = true;
    document.getElementById(BUTTON_RESTART_GAME).disabled = false;
    game.isActive = false;
    clearInterval(timerElapsedTime);
    clearInterval(timerRemainingTime);
    const elapsedTime = (Date.now() - game.startTime) / 1000;
    storeGameResult(game.difficulty, wasWin, elapsedTime);
    if (wasManual || wasTimeout || !wasWin) {
        revealAllMines();
        if (wasManual) {
            alert("White flag raised! There's no shame in a tactical exit.");
        } else if (wasTimeout) {
            alert("Tick-tock... boom! The timer won this round.");
        } else {
            alert("Kaboom! That wasn't the best spot to click.");
        };
    } else {
        alert("Flawless minesweeping. Ever considered bomb defusal as a career?");
    };
}

function restartGame() {
    document.getElementById(BUTTON_RESTART_GAME).disabled = true;
    timerElapsedTime = null;
    timerRemainingTime = null;
    setDifficulty(game.difficulty);
    startGame();
}

function showMinesLeft() {
    const flagsUsed = game.flaggedCells.flat().filter(Boolean).length;
    const minesLeft = game.numMines - flagsUsed;
    document.getElementById(SPAN_MINES_LEFT).textContent = minesLeft;
}

function showElapsedTime() {
    if (!game.isActive || !game.startTime) {
        return;
    };
    let x = Math.floor((Date.now() - game.startTime) / 1000);
    document.getElementById(SPAN_TIME_ELAPSED).textContent = x;
    if (x >= game.maxGameDuration) {
        endGame(false, true, false);
    };
}

function showRemainingTime() {
    if (!game.isActive || !game.startTime) {
        return;
    };
    let x = game.maxGameDuration - Math.floor((Date.now() - game.startTime) / 1000);
    if (x <= 0) {
        x = 0;
    };
    document.getElementById(SPAN_REMAINING_TIME).textContent = x;
}

function storeGameResult(difficulty, wasWin, elapsedTime) {
    const storageKey = "game_history_" + loggedUser;
    const gameHistory = JSON.parse(localStorage.getItem(storageKey)) || [];
    const gameResult = {
        difficulty: difficulty,
        win: wasWin,
        elapsedTime: elapsedTime
    };
    gameHistory.push(gameResult);
    localStorage.setItem(storageKey, JSON.stringify(gameHistory));
}