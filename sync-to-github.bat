@echo off
setlocal EnableDelayedExpansion
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

REM ---- 1/6  init repo + remote ----
if not exist ".git\" (
  echo [1/6] First run: initializing local repository...
  git init -b %BRANCH% || goto :fail
) else (
  echo [1/6] Local repository OK
)
git remote get-url origin >nul 2>nul || git remote add origin "%REPO_URL%"
git remote set-url origin "%REPO_URL%" || goto :fail

REM ---- 2/6  detect commits that were committed but never pushed ----
echo [2/6] Checking for unpushed commits...
for /f "delims=" %%a in ('git rev-list --count origin/%BRANCH%..HEAD 2^>nul') do (
  if not "%%a"=="0" echo       [i] %%a local commit not pushed yet, will push it too
)

REM ---- 3/6  stage everything (new / modified / deleted) ----
echo [3/6] Staging all files...
git add -A || goto :fail

REM ---- 4/6  commit only when there are changes ----
set "MSG=%~1"
if "%MSG%"=="" set "MSG=sync: %date% %time%"
git diff --cached --quiet
if errorlevel 1 (
  echo [4/6] Committing: %MSG%
  git commit -m "%MSG%" || goto :fail
) else (
  echo [4/6] No local changes, skipping commit
)

REM ---- 5/6  rebase onto remote (never force-push) ----
echo [5/6] Pulling remote updates...
git ls-remote --exit-code --heads origin %BRANCH% >nul 2>nul
if errorlevel 1 (
  echo       Remote branch not created yet, skipping pull
) else (
  git pull --rebase origin %BRANCH% || goto :fail
)

REM ---- 6/6  push and verify ----
echo [6/6] Pushing to %REPO_URL%
git push -u origin %BRANCH% || goto :fail

echo       Verifying local vs remote...
set "LOCAL_HASH="
set "REMOTE_HASH="
for /f "tokens=1" %%h in ('git rev-parse HEAD') do set "LOCAL_HASH=%%h"
for /f "tokens=1" %%r in ('git ls-remote origin refs/heads/%BRANCH% 2^>nul') do set "REMOTE_HASH=%%r"
if "!REMOTE_HASH!"=="" (
  echo       [i] Cannot read remote hash, verification skipped - network issue?
) else (
  if not "!LOCAL_HASH!"=="!REMOTE_HASH!" (
    echo [X] MISMATCH: local !LOCAL_HASH! / remote !REMOTE_HASH!
    echo     Some commits were NOT pushed. Run this script again.
    goto :fail
  ) else (
    echo       OK  local == remote : !LOCAL_HASH!
  )
)

echo.
echo [OK] Sync finished.
git log --oneline -1
echo.
echo Press any key to close this window...
pause >nul
exit /b 0

:fail
echo.
echo [X] Sync FAILED. Common causes: GitHub login expired, sign-in window
echo     not completed, network error, or a rebase conflict.
echo [i] Commits already made locally are NOT lost - fix the issue and
echo     simply run this script again to push them.
echo.
echo Press any key to close this window...
pause >nul
exit /b 1
