package engine

import m "core:math"

PI :: 3.14159265358979323846

engine :: struct {
    playing: bool,
    phase: f32,
    frequency: f32,
    sample_rate: u32,
    gain: f32,
}

next_sample :: proc(e: ^engine) -> f32 {
    if !e.playing {
        return 0.0
    }
    phase_inc := e.frequency / f32(e.sample_rate)

    sample := f32(m.sin(e.phase * 2.0 * PI))
    e.phase += phase_inc
    if e.phase >= 1.0 {
        e.phase -= 1.0
    }

    sample *= f32(e.gain)
    return sample
}
