package imgui_impl_opengl3

import im "./../../"

@(require, export)
foreign import imguilib "system:apollo_ui"

@(default_calling_convention = "c", link_prefix = "ImGui_ImplOpenGL3_")
foreign imguilib {
	// Follow "Getting Started" link and check examples/ folder to learn about using backends!
	Init :: proc(
		glsl_version: cstring = nil) -> bool ---
	Shutdown :: proc() ---
	NewFrame :: proc() ---
	RenderDrawData :: proc(
		draw_data: ^im.DrawData) ---

	// (Optional) Called by Init/NewFrame/Shutdown
	CreateDeviceObjects :: proc() -> bool ---
	DestroyDeviceObjects :: proc() ---

	// (Advanced) Use e.g. if you need to precisely control the timing of texture
	// updates (e.g. for staged rendering), by setting ImDrawData::Textures = nullptr
	// to handle this manually.
	UpdateTexture :: proc(
		tex: ^im.TextureData) ---
}
