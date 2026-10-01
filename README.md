# Apollo

An Odin starter for experimenting with a software synthesiser UI. It opens a
GLFW/OpenGL 3 window with Dear ImGui controls and a real ImPlot oscilloscope.
The frequency and gain controls update the plotted waveform; it does not produce
audio yet.

All application dependencies needed for a native build are under `vendor/`:
Dear ImGui, ImPlot, their generated C APIs, GLFW, and the thin Odin declarations
for those APIs. No prebuilt third-party libraries are committed. See
[`vendor/VERSIONS.md`](vendor/VERSIONS.md) for the exact revisions and licenses.

## Nix / Linux

Run the pinned release build:

```sh
nix run
```

For an editable development build:

```sh
nix develop
apollo-run
```

`apollo-build -debug` produces `build/apollo`. CMake compiles the vendored C and
C++ code into `libapollo_ui`, while Odin compiles the application and links that
library. The flake supplies the compiler and Linux system development libraries;
the UI source itself does not come from Nix packages.

## Windows

Install Odin, CMake, and the MSVC compiler plus Windows SDK. Then use either the
PowerShell initialized by PortableBuildTools or an x64 Native Tools PowerShell
from the repository root:

```powershell
./scripts/build.ps1
./build/apollo.exe
```

The script builds GLFW and the UI bridge from the same vendored sources, links
the Odin program, and places `glfw3.dll` beside the executable. This path is
designed for native Windows builds; the Nix flake currently targets Linux.
It automatically chooses Ninja, NMake, or Visual Studio as available. To force
a generator, set `CMAKE_GENERATOR` before running it, for example:

```powershell
$env:CMAKE_GENERATOR = "NMake Makefiles"
./scripts/build.ps1
```

## Layout

- `src/main.odin` — window, synth controls, and ImPlot waveform.
- `CMakeLists.txt` — portable C/C++ build for GLFW, ImGui, and ImPlot.
- `vendor/odin` — Odin declarations only; these provide typed, idiomatic calls
  over the C APIs and contain no native binaries.
- `vendor/generated` — the Dear ImGui C wrapper generated from the pinned source.

## Next steps

- Add a real-time audio callback and oscillator voice.
- Separate UI and audio state with a lock-free command queue.
- Feed captured audio into the oscilloscope and add an FFT spectrum plot.
