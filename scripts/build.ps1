$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$NativeBuild = Join-Path $Root "build/native"
$Output = Join-Path $Root "build/apollo.exe"

cmake -S $Root -B $NativeBuild -A x64
cmake --build $NativeBuild --config Debug

$LibraryPath = Join-Path $NativeBuild "lib"
odin build (Join-Path $Root "src") `
    "-collection:apollo=$(Join-Path $Root 'vendor/odin')" `
    "-extra-linker-flags:/LIBPATH:$LibraryPath" `
    "-out:$Output" `
    -debug

Copy-Item (Join-Path $NativeBuild "bin/glfw3.dll") (Join-Path $Root "build/glfw3.dll") -Force
