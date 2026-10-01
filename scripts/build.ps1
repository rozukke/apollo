$ErrorActionPreference = "Stop"

function Assert-Command([string]$Name, [string]$Help) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name was not found. $Help"
    }
}

$Root = Split-Path -Parent $PSScriptRoot
$Output = Join-Path $Root "build/apollo.exe"

Assert-Command "cmake.exe" "Install CMake and add it to PATH."
Assert-Command "odin.exe" "Install Odin and add it to PATH."
Assert-Command "cl.exe" "Run this from the shell initialized by PortableBuildTools, or from an x64 Native Tools shell."
Assert-Command "link.exe" "Activate the MSVC x64 toolchain in this shell before building."

# -A is valid for Visual Studio generators only. Portable MSVC setups commonly
# expose NMake or Ninja instead, so select a generator that is actually present.
$Generator = $env:CMAKE_GENERATOR
if ([string]::IsNullOrWhiteSpace($Generator)) {
    if (Get-Command "ninja.exe" -ErrorAction SilentlyContinue) {
        $Generator = "Ninja"
    } elseif (Get-Command "nmake.exe" -ErrorAction SilentlyContinue) {
        $Generator = "NMake Makefiles"
    } else {
        $Generator = "Visual Studio 17 2022"
    }
}

$GeneratorSlug = $Generator -replace '[^A-Za-z0-9]+', '-'
$NativeBuild = Join-Path $Root "build/native/windows-$GeneratorSlug"
$ConfigureArgs = @("-S", $Root, "-B", $NativeBuild, "-G", $Generator)

if ($Generator -like "Visual Studio*") {
    $ConfigureArgs += @("-A", "x64")
} else {
    $ConfigureArgs += "-DCMAKE_BUILD_TYPE=Debug"
}

cmake @ConfigureArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

cmake --build $NativeBuild --config Debug
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$LibraryPath = Join-Path $NativeBuild "lib"
$ExpectedLibraries = @("apollo_ui.lib", "glfw3dll.lib")
foreach ($Library in $ExpectedLibraries) {
    $LibraryFile = Join-Path $LibraryPath $Library
    if (-not (Test-Path $LibraryFile)) {
        throw "Expected native library was not produced: $LibraryFile"
    }
}

odin build (Join-Path $Root "src") `
    "-collection:apollo=$(Join-Path $Root 'vendor/odin')" `
    "-extra-linker-flags:/LIBPATH:$LibraryPath" `
    "-out:$Output" `
    -debug
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Copy-Item (Join-Path $NativeBuild "bin/glfw3.dll") (Join-Path $Root "build/glfw3.dll") -Force
