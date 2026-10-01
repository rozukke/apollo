# Vendored dependencies

The project builds these source snapshots directly; no generated object files
or prebuilt libraries are checked in.

| Component | Revision | License |
| --- | --- | --- |
| Dear ImGui (docking) | `v1.92.9b-docking` (`b48d1afb`) | MIT |
| Dear Bindings | `DearBindings_v0.21_ImGui_v1.92.9b-docking` (`c9ff6491`) | MIT |
| ImPlot | `v1.0` (`524f9fcd`) | MIT |
| cimplot | `75a03832` (generated for ImPlot 1.0) | MIT |
| cimgui, docking branch | `125f397e` (generated for ImGui 1.92.9b) | MIT |
| GLFW | `3.4` (`7b6aead9`) | zlib/libpng |
| Odin ImGui declarations | `Capati/odin-imgui@5402a803` | MIT |
| Odin ImPlot declarations | `Hilderin/OdinVulkan@15251a20`, locally audited | MIT |

`vendor/generated/imgui/dcimgui.*` is generated from the vendored ImGui
headers with the vendored Dear Bindings generator. The Odin declarations are
patched to link the CMake-produced `apollo_ui` library instead of checked-in
platform binaries. Two ImPlot draw-list calls are updated to ImGui 1.92.8's
new argument order so the native library can retain the same obsolete-API
configuration used to generate the Odin declarations.
