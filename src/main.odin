package main

import "base:runtime"
import "core:fmt"
import "core:math"

import "apollo:glfw"
import gl "vendor:OpenGL"

import im "apollo:imgui"
import imglfw "apollo:imgui/backends/glfw"
import imgl "apollo:imgui/backends/opengl3"
import plot "apollo:implot"

import ma "vendor:miniaudio"
import e "engine"

data_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frame_count: u32) {
	// inject default context (odin quirk)
	context = runtime.default_context()

	engine := (^e.engine)(device.pUserData)
	out := cast([^]f32)output

	channels := device.playback.channels

	out_idx := 0
	for i in 0..<frame_count {
		sample := e.next_sample(engine)

		for c in 0..<channels {
			out[out_idx] = sample
			out_idx += 1
		}
	}
}

GLSL_VERSION :: "#version 150"

Synth_State :: struct {
	engine: e.engine,
	gain:      f32,
	attack:    f32,
	release:   f32,
}

glfw_error_callback :: proc "c" (error: i32, description: cstring) {
	context = runtime.default_context()
	fmt.eprintfln("GLFW error %d: %s", error, description)
}

draw_waveform :: proc(state: ^Synth_State) {
	xs: [256]f32
	ys: [256]f32
	cycles := 1.0 + (f32(state.engine.frequency) - 20.0) / 1980.0 * 7.0
	for sample in 0 ..< len(xs) {
		t := f32(sample) / f32(len(xs) - 1)
		xs[sample] = t
		ys[sample] = f32(math.sin(f64(t * cycles * 2 * math.PI))) * f32(state.engine.gain)
	}

	if plot.BeginPlot("Oscilloscope", im.Vec2{-1, 220}, {.NoTitle}) {
		plot.SetupAxes("Phase", "Amplitude", {}, {.AutoFit})
		plot.SetupAxesLimits(0, 1, -1.05, 1.05, .Once)
		plot.PlotLine_FloatPtrFloatPtr(
			"Oscillator",
			raw_data(xs[:]),
			raw_data(ys[:]),
			i32(len(xs)),
		)
		plot.EndPlot()
	}
}

draw_synth :: proc(state: ^Synth_State) {
	main_window_flags := im.WINDOW_FLAGS_NO_DECORATION + im.WindowFlags{.NoMove, .NoResize, .NoSavedSettings}
	viewport := im.GetMainViewport()
	im.SetNextWindowSize(viewport.Size)
	im.SetNextWindowPos(viewport.Pos)

	im.Begin("Apollo", nil, main_window_flags)
	im.Text("A small signal-path playground")
	im.Separator()

	im.Text("Oscillator")
	im.SliderFloat("Frequency", &state.engine.frequency, 20, 2000, "%.0f Hz")
	im.SliderFloat("Gain", &state.engine.gain, 0, 1, "%.2f")
	im.Spacing()

	im.Text("Envelope")
	im.SliderFloat("Attack", &state.attack, 0.001, 2, "%.3f s")
	im.SliderFloat("Release", &state.release, 0.01, 4, "%.2f s")
	im.Spacing()

	if im.Button(state.engine.playing ? "Stop" : "Play") {
		state.engine.playing = !state.engine.playing
	}
	im.SameLine()
	im.Text(state.engine.playing ? "signal active" : "signal idle")
	im.Spacing()

	draw_waveform(state)
	im.End()
}

main :: proc() {
	glfw.SetErrorCallback(glfw_error_callback)
	ensure(bool(glfw.Init()))
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(1100, 720, "Apollo", nil, nil)
	ensure(window != nil)
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	im.CHECKVERSION()
	im.CreateContext()
	defer im.DestroyContext()
	im.StyleColorsDark()
	plot_context := plot.CreateContext()
	ensure(plot_context != nil)
	defer {
		plot.DestroyDefaultSpec()
		plot.DestroyContext(plot_context)
	}

	io := im.GetIO()
	io.ConfigFlags |= {.NavEnableKeyboard}

	ensure(imglfw.InitForOpenGL(window, true))
	defer imglfw.Shutdown()
	ensure(imgl.Init(GLSL_VERSION))
	defer imgl.Shutdown()

	clear_color := im.Vec4{0.025, 0.032, 0.045, 1.0}

	// Audio setup
	engine := e.engine{
		phase = 0.0,
		frequency = 440.0, // A4
		sample_rate = 48000,
		gain = 0.7,
	}

	state := Synth_State{
		attack = 0.02,
		release = 0.35,
		engine = engine,
	}

	device_config := ma.device_config_init(.playback)
	device_config.playback.format = .f32
	device_config.playback.channels = 2
	device_config.sampleRate = engine.sample_rate
	device_config.dataCallback = data_callback
	device_config.pUserData = &state.engine

	device: ma.device
	if ma.device_init(nil, &device_config, &device) != .SUCCESS {
		fmt.eprintln("Failed to initialize playback device.")
		return
	}
	defer ma.device_uninit(&device)

	if ma.device_start(&device) != .SUCCESS {
		fmt.eprintln("Failed to start playback device.")
		return
	}

	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		if glfw.GetWindowAttrib(window, glfw.ICONIFIED) != 0 {
			imglfw.Sleep(10)
			continue
		}

		imgl.NewFrame()
		imglfw.NewFrame()
		im.NewFrame()

		draw_synth(&state)

		im.Render()
		display_width, display_height := glfw.GetFramebufferSize(window)
		gl.Viewport(0, 0, display_width, display_height)
		gl.ClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		imgl.RenderDrawData(im.GetDrawData())
		glfw.SwapBuffers(window)
	}
}
