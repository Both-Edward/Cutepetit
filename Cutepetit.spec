# -*- coding: utf-8 -*-
# -*- mode: python ; coding: utf-8 -*-
# ============================================================
# Cutepetit PyInstaller spec  (v1.1.0)
#
# 构建命令（在项目根目录执行）：
#   pyinstaller Cutepetit.spec
#
# 输出目录：dist\Cutepetit\
#
# 注意：本 spec 针对 PyInstaller 5.x 编写（onedir 平铺结构）。
#       若使用 PyInstaller 6.x，产物会在 dist\Cutepetit\_internal\
#       下多一层目录，installer.nsi 中已同步处理两种情况。
# ============================================================

import sys
import os
from PyInstaller.utils.hooks import collect_data_files, collect_dynamic_libs

block_cipher = None

# ---------------------------------------------------------------------------
# Python 运行时 DLL（避免在未安装 Python 的机器上崩溃）
# ---------------------------------------------------------------------------
_py_dll_name = f"python{sys.version_info.major}{sys.version_info.minor}.dll"
_py_dll_path = os.path.join(sys.base_prefix, _py_dll_name)
_binaries = [(_py_dll_path, ".")] if os.path.exists(_py_dll_path) else []

# ---------------------------------------------------------------------------
# pygame SDL2 动态库（pygame 依赖的 .dll 不会被 PyInstaller 自动发现）
# ---------------------------------------------------------------------------
try:
    _binaries += collect_dynamic_libs("pygame")
except Exception:
    pass

# ---------------------------------------------------------------------------
# 数据文件
#   Pets / Music / config.json 在运行时需要可写，因此不放入只读的
#   _MEIPASS，而是直接复制到 dist\Cutepetit\ 根目录。
#   installer.nsi 负责将整个 dist\Cutepetit\ 复制到用户的
#   %LOCALAPPDATA%\Cutepetit\（可写路径）。
#   重装时 config.json 由安装脚本判断是否跳过，此处照常打包。
# ---------------------------------------------------------------------------
_datas = [
    ("Pets",        "Pets"),        # 宠物动画资源（GIF / ICO / JSON）
    ("ico",         "ico"),         # 窗口图标 / 托盘图标
    ("Music",       "Music"),       # 默认音乐文件夹（含示例 mp3）
    ("Language",    "Language"),    # 语言包（zh_CN / zh_TW / en_US / ja_JP / fr_FR / ko_KR）
    ("config.json", "."),           # 默认配置文件
]

# 收集 pystray Windows 后端资源（如有）
try:
    _datas += collect_data_files("pystray")
except Exception:
    pass

# ---------------------------------------------------------------------------
# Hidden imports
# ---------------------------------------------------------------------------
_hidden = [
    # ── openai SDK（AI 对话功能，可选）────────────────────────────────────────
    "openai",
    "openai._models",
    "openai.resources",

    # ── Pillow ──────────────────────────────────────────────────────────────
    "PIL._tkinter_finder",
    "PIL.Image",
    "PIL.ImageTk",
    "PIL.ImageSequence",
    "PIL.GifImagePlugin",
    "PIL.IcoImagePlugin",
    "PIL.PngImagePlugin",

    # ── pystray（Windows 后端）──────────────────────────────────────────────
    "pystray._win32",
    "pystray._base",

    # ── pygame 音频 ──────────────────────────────────────────────────────────
    "pygame",
    "pygame.mixer",
    "pygame.mixer_music",
    "pygame.base",

    # ── screeninfo 多显示器 ──────────────────────────────────────────────────
    "screeninfo",
    "screeninfo.enumerators",
    "screeninfo.enumerators.windows",

    # ── send2trash 回收站 ────────────────────────────────────────────────────
    "send2trash",
    "send2trash.plat_win",

    # ── numpy（gif_loader 中的预乘 alpha 缩放依赖）──────────────────────────
    # 补充 _dtype_ctypes，部分 numpy 版本打包后运行时会缺失该模块
    "numpy",
    "numpy.core",
    "numpy.core._multiarray_umath",
    "numpy.core._dtype_ctypes",

    # ── Windows 系统模块 ─────────────────────────────────────────────────────
    "winreg",
    "ctypes",
    "ctypes.wintypes",

    # ── 标准库（部分构建环境下静态分析可能漏检）────────────────────────────
    # 保留 email / html：urllib.request 内部依赖 email.message 和
    # html.parser 处理 HTTP 响应头，不应排除
    "threading",
    "urllib.request",
    "urllib.error",
    "email",
    "email.message",
    "html",
    "html.parser",
    "json",
    "shutil",
    "math",
    "random",
    "webbrowser",

    # ── 项目自身包 ───────────────────────────────────────────────────────────
    "core",
    "core.config",
    "core.gif_loader",
    "core.pet_data",
    "core.i18n",
    "ui",
    "ui.theme",
    "ui.helpers",
    "ui.music_player",
    "compat",
    "compat.autostart",
    "compat.dpi",
    "compat.trash",
]

a = Analysis(
    ["main.py"],
    pathex=["."],
    binaries=_binaries,
    datas=_datas,
    hiddenimports=_hidden,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        # 排除无关的重型库，减小包体积
        # 注意：email / html 已从此列表移除，见上方 hidden imports 说明
        "matplotlib",
        "scipy",
        "pandas",
        "IPython",
        "jupyter",
        "PyQt5",
        "PyQt6",
        "wx",
        "tkinter.test",
        "unittest",
        "xmlrpc",
        "http.server",
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,      # COLLECT 模式（onedir），便于 NSIS 打包
    name="Cutepetit",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[
        # SDL / pygame 相关 DLL 压缩后可能损坏，全部排除
        "SDL2.dll",
        "SDL2_mixer.dll",
        "libopus-0.dll",
        "libvorbis-0.dll",
        "libvorbisfile-3.dll",
        "libogg-0.dll",
        "libmpg123-0.dll",
        "libFLAC-8.dll",
    ],
    console=False,                          # GUI 应用，不弹控制台窗口
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon="ico/Cutepetit ico.ico",
    version_file=None,   # 可选：提供 file_version_info.txt 路径以在右键属性中显示版本号
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[
        "SDL2.dll",
        "SDL2_mixer.dll",
        "libopus-0.dll",
        "libvorbis-0.dll",
        "libvorbisfile-3.dll",
        "libogg-0.dll",
        "libmpg123-0.dll",
        "libFLAC-8.dll",
    ],
    name="Cutepetit",     # 输出到 dist\Cutepetit\
)
