# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[("C:/Users/vmjcv/Envs/playwright/Lib/site-packages/playwright_stealth","playwright_stealth"),
    ("C:/Users/vmjcv/Envs/playwright/Lib/site-packages/playwright/driver","playwright/driver"),
    ("C:/Users/vmjcv/Envs/playwright/Lib/site-packages/undetected_playwright","undetected_playwright"),
	],
    hiddenimports=["sse_starlette","undetected_playwright"],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='main',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
