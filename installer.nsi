; ============================================================
; Cutepetit Installer Script  v1.1.0
; 工具：NSIS 3.x  (https://nsis.sourceforge.io/)
;
; 构建顺序：
;   1. pip install pyinstaller
;   2. pyinstaller Cutepetit.spec
;      （产物在 dist\Cutepetit\）
;   3. makensis installer.nsi
;      （输出 Cutepetit-Setup-1.0.1.exe）
;
; 安装路径：%LOCALAPPDATA%\Cutepetit\
;   - 无需管理员权限（UAC）
;   - Pets\ / Music\ / config.json 均可写
;
; 卸载策略：
;   - 提示用户是否保留 Pets\ / Music\ / config.json
;   - 清理快捷方式、注册表、开机自启动项
; ============================================================

Unicode True

; ── 应用信息 ──────────────────────────────────────────────────
!define APP_NAME      "Cutepetit"
!define APP_VERSION   "1.1.0"
!define APP_PUBLISHER "Edward"
!define APP_EXE       "Cutepetit.exe"
!define APP_DIR       "Cutepetit"
!define APP_URL       "https://github.com/Both-Edward/Cutepetit"

; 控制面板"程序和功能"中显示的占用大小（单位 KB）
!define ESTIMATED_SIZE 90000

; 注册表路径
!define REG_APP       "Software\${APP_NAME}"
!define REG_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

; ── 输出设置 ──────────────────────────────────────────────────
Name    "${APP_NAME} ${APP_VERSION}"
OutFile "Cutepetit-Setup-${APP_VERSION}.exe"

; 安装到 %LOCALAPPDATA%\Cutepetit\，无需 UAC
InstallDir      "$LOCALAPPDATA\${APP_DIR}"
InstallDirRegKey HKCU "${REG_APP}" "InstallLocation"

RequestExecutionLevel user

; ── 压缩 ──────────────────────────────────────────────────────
SetCompressor /SOLID lzma

; ── MUI2 界面 ─────────────────────────────────────────────────
!include "MUI2.nsh"
!include "LogicLib.nsh"

!define MUI_ABORTWARNING
!define MUI_ICON   "ico\Cutepetit ico.ico"
!define MUI_UNICON "ico\Cutepetit ico.ico"
!define MUI_FINISHPAGE_RUN      "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "立即启动 ${APP_NAME}"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

; ============================================================
; 安装 Section
; ============================================================
Section

    ; 若程序正在运行则先关闭，等待文件句柄释放
    ExecWait 'taskkill /F /IM "${APP_EXE}"'
    Sleep 800

    ; 目标根目录
    SetOutPath "$INSTDIR"

    ; ── 复制 PyInstaller 产物 ──────────────────────────────────
    ; 复制 PyInstaller 产物（PyInstaller 6.x onedir 结构）：
    ;   dist\Cutepetit\Cutepetit.exe  （主程序，可写目录根）
    ;   dist\Cutepetit\_internal\*          （只读运行库 + 资源）
    ; File /r 整体递归复制，目标根为 $INSTDIR
    File /r "dist\${APP_DIR}\*"

    ; config.json 由 PyInstaller 6.x 打包至 _internal\ 子目录
    ; 安装时复制到 $INSTDIR\ 根目录（exe 同级，可写）
    ; 首次安装写入默认配置，升级时保留用户已有配置
    ; IfFileExists "$INSTDIR\config.json" config_exists config_missing
    ; config_missing:
    ;     SetOutPath "$INSTDIR"
    ;     File "dist\${APP_DIR}\_internal\config.json"
    ; config_exists:

    ; ── 写注册表（HKCU，无需管理员）──────────────────────────
    WriteRegStr   HKCU "${REG_UNINSTALL}" "DisplayName"      "${APP_NAME}"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "DisplayVersion"   "${APP_VERSION}"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "Publisher"        "${APP_PUBLISHER}"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "InstallLocation"  "$INSTDIR"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "UninstallString"  '"$INSTDIR\Uninstall.exe"'
    WriteRegStr   HKCU "${REG_UNINSTALL}" "DisplayIcon"      "$INSTDIR\${APP_EXE}"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "URLInfoAbout"     "${APP_URL}"
    WriteRegDWORD HKCU "${REG_UNINSTALL}" "NoModify"         1
    WriteRegDWORD HKCU "${REG_UNINSTALL}" "NoRepair"         1
    WriteRegDWORD HKCU "${REG_UNINSTALL}" "EstimatedSize"    ${ESTIMATED_SIZE}
    WriteRegStr   HKCU "${REG_APP}"       "InstallLocation"  "$INSTDIR"
    WriteRegStr   HKCU "${REG_APP}"       "Version"          "${APP_VERSION}"

    ; ── 生成卸载程序 ──────────────────────────────────────────
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; ── 快捷方式 ──────────────────────────────────────────────
    CreateShortcut "$DESKTOP\${APP_NAME}.lnk" \
        "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0 \
        SW_SHOWNORMAL "" "${APP_NAME}"

    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortcut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" \
        "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
    CreateShortcut "$SMPROGRAMS\${APP_NAME}\卸载 ${APP_NAME}.lnk" \
        "$INSTDIR\Uninstall.exe"

SectionEnd

; ============================================================
; 卸载 Section
; ============================================================
Section "Uninstall"

    ; 先关闭正在运行的程序
    ExecWait 'taskkill /F /IM "${APP_EXE}"'
    Sleep 800

    ; ── 询问是否保留用户数据 ──────────────────────────────────
    MessageBox MB_YESNO|MB_ICONQUESTION \
        "是否同时删除自定义宠物和音乐文件？$\n选择【否】将保留 Pets\ Music\ 和 config.json" \
        IDYES remove_all IDNO keep_userdata

    remove_all:
        ; 删除整个安装目录
        RMDir /r "$INSTDIR"
        Goto cleanup_shortcuts

    keep_userdata:
        ; 仅删除程序文件，保留用户数据目录和配置
        ; 兼容 PyInstaller 5.x（平铺）和 6.x（_internal 子目录）
        RMDir /r "$INSTDIR\_internal"
        Delete "$INSTDIR\${APP_EXE}"
        Delete "$INSTDIR\Uninstall.exe"
        Delete "$INSTDIR\*.dll"
        Delete "$INSTDIR\*.pyd"
        Delete "$INSTDIR\*.manifest"
        Delete "$INSTDIR\*.zip"
        Delete "$INSTDIR\python*.pkg"
        RMDir /r "$INSTDIR\ico"
        RMDir /r "$INSTDIR\Language"
        ; 尝试删除目录本身（非空则自动跳过）
        RMDir "$INSTDIR"

    cleanup_shortcuts:
    ; ── 删除快捷方式 ──────────────────────────────────────────
    Delete "$DESKTOP\${APP_NAME}.lnk"
    Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
    Delete "$SMPROGRAMS\${APP_NAME}\卸载 ${APP_NAME}.lnk"
    RMDir  "$SMPROGRAMS\${APP_NAME}"

    ; ── 清理注册表 ────────────────────────────────────────────
    ; 注销开机自启动（程序内开启时写入此键）
    DeleteRegValue HKCU \
        "Software\Microsoft\Windows\CurrentVersion\Run" "${APP_NAME}"
    DeleteRegKey HKCU "${REG_UNINSTALL}"
    DeleteRegKey HKCU "${REG_APP}"

SectionEnd
