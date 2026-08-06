# Audio

Audio assets for Slowbrew. Place the following `.caf` files here:

| File | When it plays | Duration |
|------|--------------|----------|
| `chime_in.caf` | Walk-in animation begins | ≤ 2 seconds, non-looping |
| `chime_out.caf` | Walk-out animation begins (break ends) | ≤ 2 seconds, non-looping |
| `ambient_brew.caf` | While brewing animation is active | Loops seamlessly |

## Format notes

- `.caf` (Core Audio Format) is preferred on macOS — convert from MP3/WAV
  using `afconvert` if needed:
  `afconvert -f caff -d LEF32@44100 input.wav output.caf`
- Ambient audio should loop seamlessly (start and end points match).
- All audio is suppressed when the user disables sound in Settings.
