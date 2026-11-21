@echo off
setlocal
chcp 65001 >nul 2>nul
cd /d "%~dp0"

REM ==== Config: change these two lines if the repo moves ====
set "REPO_URL=https://github.com/alaskevin2006-del/AI-Learning.git"
set "BRANCH=main"

echo ============================================
echo  AI-Learning  ^>  GitHub  one-click sync
echo ============================================

where git >nul 2>nul
if errorlevel 1 (
  echo [X] git not found. Install Git for Windows first.
  goto :fail
)

REM ---- 1/5  init repo + remote ----
if not exist ".git\" (
  echo [1/5] First run: initializing local repository...
  git init -b %BRANCH% || goto :fail
) else (
  echo [1/5] Local repository OK
)
git remote get-url origin >nul 2>nul || git remote add origin "%REPO_URL%"
git remote set-url origin "%REPO_URL%" || goto :fail

REM ---- 2/5  stage everything (new / modified / deleted) ----
echo [2/5] Staging all files...
git add -A || goto :fail

REM ---- 3/5  commit only when there are changes ----
set "MSG=%~1"
if "%MSG%"=="" set "MSG=sync: %date% %time%"
git diff --cached --quiet
if errorlevel 1 (
  echo [3/5] Committing: %MSG%
  git commit -m "%MSG%" || goto :fail
) else (
  echo [3/5] No local changes, skipping commit
)

REM ---- 4/5  rebase onto remote (never force-push) ----
echo [4/5] Pulling remote updates...
git ls-remote --exit-code --heads origin %BRANCH% >nul 2>nul
if errorlevel 1 (
  echo       Remote branch not created yet, skipping pull
) else (
  git pull --rebase origin %BRANCH% || goto :fail
)

REM ---- 5/5  push ----
echo [5/5] Pushing to %REPO_URL%
git push -u origin %BRANCH% || goto :fail

echo.
echo [OK] Sync finished.
git log --oneline -1
echo.
echo Press any key to close this window...
pause >nul
exit /b 0

:fail
echo.
echo [X] Sync FAILED. Common causes: GitHub login expired, network error,
echo     or a rebase conflict (resolve it manually, then run again).
echo.
echo Press any key to close this window...
pause >nul
exit /b 1
