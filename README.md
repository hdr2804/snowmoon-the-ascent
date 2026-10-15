# THE ASCENT — a Snowmoon Chapter 6 film

An audiovisual adaptation of one scene from **Snowmoon**, the science-fiction
novel by Vitalik Buterin, released under **GPL v3**.

- **Scene:** Chapter 6 — Gladias climbs 200 metres of outdoor staircase to a
  mountain tower top and is anonymously confirmed as a Keeper of the Order,
  before ten robed Order members and a glowing green circle.
- **Runtime:** ~83 seconds, 16:9, 1920x1080.
- **Audio:** fully synthesized (wind, drone score, one chime). No voiceover,
  no stock music. Dialogue is subtitled only — all faces are hidden by
  Veridian privacy robes, faithful to the scene's anonymity theme.
- **Bounty:** [poidh mainnet #34 — Bring Snowmoon to Life](https://poidh.xyz/mainnet/bounty/34)

## Repo contents

| File | What it is |
|---|---|
| `STORYBOARD.md` | Final shot-by-shot storyboard (8 shots + end card) |
| `PROMPTS.md` | The exact image-generation prompts per shot |
| `subs.srt` | Burned-in subtitles (dialogue from the chapter, paraphrased) |
| `build.sh` | Reproducible ffmpeg build: stills → motion → audio → final |
| `PROCESS.md` | Full process notes: tool choices, QC, what failed, limitations |
| `stills/` | The AI-generated key stills (16:9) used as the film's base |
| `final/the-ascent.mp4` | The finished film |
| `final/qc-contact-sheet.jpg` | 3×3 QC contact sheet (one frame per shot) |
| `make_audio.py` | Deterministic audio synthesis (numpy, fixed seed) |
| `build/` | Regenerable scratch: normalized stills, segments, wavs (not needed in the public repo) |

## How to reproduce

Requirements: ffmpeg 8.x built with libass + libfreetype (for subtitle
burn-in), DejaVu Sans fonts (standard on most Linux).

```bash
bash build.sh
```

The script: normalizes the stills to 1920x1080, renders each shot with
Ken Burns motion (ffmpeg `zoompan`), assembles with crossfades, synthesizes
the audio track from scratch (pink-noise wind, layered sine drone score,
one sine chime), burns in subtitles + the device-screen confirmation text +
end card, and encodes the final at CRF 18.

The source stills were generated with an AI image pipeline (prompts in
`PROMPTS.md`); shot 7 ("lit") was produced by editing shot 6 ("dark") so the
composition matches exactly. No AI video generation was used — the video
generator was unavailable (region-blocked), so all motion is deterministic
ffmpeg animation, fully described here.

## License

This project is released under **GPL v3**, following Snowmoon's own license
and the author's stated intent: adaptations are welcome as long as the
production pipeline is open-sourced so others can build on it.

## Credits

- Novel: *Snowmoon* by Vitalik Buterin (GPL v3), Chapter 6.
- Adaptation, storyboard, stills direction, assembly: the project author.
