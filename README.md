# Vertical Metrics

Notes and tests for vertical metrics strategies in fonts—especially how OpenType `hhea`, `typo`, and `win` values behave across important apps.

> [!WARNING]
> Work in progress: this is an evolving hypothesis based on incomplete testing. Focused on Latin and other primarily horizontal scripts; incomplete for CJK.

**Thesis:** For Latin UI and print, set a target line height with cap-centered `hhea`, InDesign-friendly `typo` + gap, `useTypoMetrics` off, and `win` matched to `hhea` (or to yMax/yMin if you must avoid clipping). That splits roles across apps better than the Google Fonts “everything follows typo” model.

## Recommended vertical metrics

Apply the same values to all styles in a family:

```py
# Set up your target line height
Line Height = UPM * 1.4  # preferred ratio; usually at least 1.2

# hheaAscender must exceed /Agrave, or you should increase your target Line Height
hheaAscender   = (Cap Height + Line Height) ÷ 2
hheaDescender  = Cap Height - hheaAscender
hheaLineGap    = 0

# typoAscender controls framing in InDesign
typoAscender   = Cap Height # some prefer to match the lowercase ascender; see note below
typoDescender  = hheaDescender
typoLineGap    = abs(hheaDescender)  # positive

# Required so macOS apps (e.g. TextEdit) use hhea correctly
useTypoMetrics = False

# Default line heights and clipping in MS Word, etc.
winAscent      = hheaAscender  # or yMax if greater and avoiding clipping matters more than cross-platform match
winDescent     = abs(hheaDescender)  # or abs(yMin) under the same tradeoff
```

This is the **Target Line Height B** strategy in testing below. Prefer matching `win` to `hhea` for consistency; use yMax/yMin only when clipping is unacceptable.

> [!NOTE]
> If, in InDesign, you want to align text based on the lowercase ascender, rather than the cap height, you can use the above recomendation, but adjust your `typo` values. This will better match results in Illustrator and Affinity, where text is aligned based on the lowercase ascender height.

```py
typoAscender   = Lowercase Ascender # top of letters like 'b' and 'd'
typoDescender  = hheaDescender
typoLineGap    = abs(hheaDescender - (Lowercase Ascender - Cap Height)) # Makes up for difference in typoAscender; this is a positive value
```

> [!WARNING]  
> For variable fonts, this strategy doesn’t align to the OpenType spec, which says:
> > In variable fonts, default line metrics should always be set using the sTypoAscender, sTypoDescender and sTypoLineGap values, and the USE_TYPO_METRICS flag in the fsSelection field should be set. The ascender, descender and lineGap fields in the 'hhea' table should be set to the same values as sTypoAscender, sTypoDescender and sTypoLineGap. The usWinAscent and usWinDescent fields should be used to specify a recommended clipping rectangle.
> > https://learn.microsoft.com/en-gb/typography/opentype/spec/os2#os2-table-and-opentype-font-variations
> 
> It is probably safest in the long run to follow the OpenType Spec. However, it is unlikely apps will change their behavior for interpreting line metrics, so it may be worth it to design based on real-world observations. This is a judgement call for you to make. That said, testing here was done primarily with static fonts, and variable fonts may yield different results.

## Video presentation

This research was presented and explained at the 2026 TypeLab font conference. Here is a re-recording of that presentation:

[![Watch the video](https://img.youtube.com/vi/51SOQx8xdSg/maxresdefault.jpg)](https://www.youtube.com/watch?v=51SOQx8xdSg)

## What are vertical metrics?

These OpenType values control how apps place lines of text by default:

1. Offset of the first line from the top of its space
2. Total height of each line, and distance between lines
3. Offset from the last line to the bottom of its space

Users can often override defaults (e.g. CSS `line-height`), but vertical centering within the line box still depends on these metrics.

They are **not** the basic “ascender” / “descender” guidelines in most font editors (those are mainly drawing guides, and can help set up zones for autohinting). Editor-specific how-tos: [Setting vertical metrics in font editors](#setting-vertical-metrics-in-font-editors).

| Name in this guide | OpenType field                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------------------ |
| **hheaAscender**   | [`ascender`](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea) (hhea)                         |
| **hheaDescender**  | [`descender`](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea) (hhea)                        |
| **hheaLineGap**    | [`lineGap`](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea) (hhea)                          |
| **typoAscender**   | [`sTypoAscender`](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#stypoascender) (OS/2)       |
| **typoDescender**  | [`sTypoDescender`](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#stypodescender) (OS/2)     |
| **typoLineGap**    | [`sTypoLineGap`](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#stypolinegap) (OS/2)         |
| **winAscent**      | [`usWinAscent`](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#uswinascent) (OS/2)           |
| **winDescent**     | [`usWinDescent`](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#uswindescent) (OS/2)         |
| **useTypoMetrics** | Bit 7 of [`fsSelection`](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#fsselection)* (OS/2) |

Editor labels vary slightly; the roles above are the same.

(*By the way: `fsSelection` is a uint16 value, which are numbered 15 to 0, so Bit 7 is in the _eigth_ column when counted from the right: `00000000 1️⃣0000000`.)

The OpenType spec says `hhea` is Apple-specific and that `sTypo*` is preferred for new layout. Apple’s docs stay vague (“highest ascender”, “lowest descender”, “typographic line gap”). Real behavior is app-specific; see below.

## Behavior by app

| App                       | Used for line layout                                                       | Notable quirks                                                                                                                                                                  |
| ------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| macOS TextEdit (CoreText) | `hhea` (even if `useTypoMetrics`)                                          | If `hheaAscender` &lt; /Agrave, macOS ignores `hhea` and assigns ~150% UPM. macOS ignores `hheaLineGap` in variable fonts.                                                      |
| InDesign                  | `typoAscender` for alignment to top of text frame                          | Default auto leading is always **120% of UPM**, ignoring typo sum. Cap-height (or near) `typoAscender` is most intuitive.                                                       |
| MS Word (Win)             | `win`, or `typo` if `useTypoMetrics`                                       | Default spacing is 1.08 + 8pt after; use **Single** to see metrics. With `useTypoMetrics`, clipping follows typo bounds, even if `win` is taller.                               |
| Chrome / Firefox          | `hhea`, or `typo` if `useTypoMetrics` (Windows); Mac Chrome follows `hhea` | Only default line-height; CSS `line-height` uses UPM, but metrics still define text position within specified CSS `line-height`. Platform mismatch when `useTypoMetrics` is on. |
| Affinity (Mac)            | `hhea` for default line height                                             | Top alignment ≈ lowercase ascender (appears to match to glyphs like “b”).                                                                                                       |
| Illustrator               | Mostly ignores these metrics                                               | Area Type aligns the top of text frames on lowercase ascenders; highlight height uses typo asc−desc (no gap). Default leading 120% UPM.                                         |

### When `useTypoMetrics` is True

Most apps follow typo metrics, but:

1. Mac apps check whether **typo**Ascender exceeds /Agrave, and apply tall metrics if not.
2. MS Word uses typo for layout **and** clipping, ignoring `win`.
3. Because of (1) and (2), typo must sit well above cap height—awkward in InDesign.
4. Chrome on Mac still follows `hhea`; Chrome/Firefox on Windows follow typo (and split `typoLineGap` half above / half below). Cross-platform mismatch if `hhea` ≠ `typo`.

> [!NOTE]
> GlyphsApp docs say typo clipping in Office is legacy (pre-2006). Current MS Word on Windows 11 still appeared to clip at typo when `useTypoMetrics`, but this could be worth re-checking.

### Implications for the recommendation

- Cap-center between `hheaAscender` and `hheaDescender` for UI web text; keep `hheaAscender` above /Agrave.
- Set `typoAscender` ≈ cap height for InDesign; use `typoLineGap` so typo + gap match the total `hhea` line height.
- Keep `useTypoMetrics` **False** so `hhea` and `win` can do their jobs without forcing `typo` to be tall to satisfy Word and Mac quirks.
- Match `win` to `hhea` when cross-app consistency matters; set `win` past yMax/yMin when any clipping is unacceptable.

Screenshots and per-app notes: [Test results](#test-results).

## Strategies compared

All strategies set the same vertical metrics across styles in a family.

| Strategy                                                            | `useTypoMetrics` | `hhea` / typo relationship                                     | `win`             | Notes                                                     |
| ------------------------------------------------------------------- | ---------------- | -------------------------------------------------------------- | ----------------- | --------------------------------------------------------- |
| **Target Line Height B** (recommended)                              | False            | Target LH → `hhea`; typoAsc = cap; typoGap fills to `hhea`     | = `hhea`          | Best cross-app consistency; possible mild first-line clip |
| Target Line Height                                                  | False            | Same as B                                                      | = yMax / \|yMin\| | Prefer when clipping must be avoided                      |
| [Google Fonts](https://googlefonts.github.io/gf-guide/metrics.html) | True             | typo = hhea; typoAsc above /Abreveacute (min: /Agrave); gaps 0 | = yMax / \|yMin\| | Absolute sum ~20–30% over UPM                             |
| Google Fonts Min                                                    | True             | Like GF; typo/hhea asc = /Agrave top                           | = yMax / \|yMin\| | Minimum GF suggestion                                     |
| Google Fonts Min Alt                                                | True             | Like Min, but typo shaped like Target (asc ≈ cap, gap fills)   | = yMax / \|yMin\| | Hybrid                                                    |
| GlyphsApp defaults                                                  | False            | typo ≈ editor asc/desc; hhea ≈ 1.2×UPM − desc                  | = `hhea`          | When custom params are unset                              |
| Adobe Fonts                                                         | —                | —                                                              | —                 | Not tested yet (Glyphs calls a related approach “Legacy”) |

Google Fonts baseline (for reference):

```py
typoAscender   = Must exceed /Abreveacute (or at least /Agrave)
typoDescender  = capHeight - typoAscender
typoLineGap    = 0

useTypoMetrics = True

hheaAscender   = typoAscender  # must match typo
hheaDescender  = typoDescender
hheaLineGap    = 0

winAscent      = yMax in family
winDescent     = abs(yMin in family)
# Absolute sum of vertical metrics should be ~20–30% greater than UPM
# (may need more for scripts outside Latin/Cyrillic/Greek)
```

GlyphsApp defaults (from experimentation; example yMax=1300, yMin=−700):

```py
typoAscender   = Basic "ascender"
typoDescender  = Basic "descender"
typoLineGap    = UPM - typoAscender

hheaAscender   = (UPM * 1.2) - basic "descender"
hheaDescender  = typoDescender
hheaLineGap    = 0

useTypoMetrics = False

winAscent      = hheaAscender
winDescent     = abs(hheaDescender)
```

### Why not just use the Google Fonts strategy?

GF metrics are dominant in many fonts due to enforcement in Google Fonts catalog + [Font Bakery](https://github.com/fonttools/fontbakery) / [Fontspector](https://github.com/fonttools/fontspector/) checks. However:

- **InDesign:** typoAsc above /Abreveacute pushes the first line down from the frame top. This is fixable in Text Frame Options, but not ideal by default.
- **Word clipping:** Setting `win` past yMax/yMin is meant to prevent clipping—but with `useTypoMetrics` True, Word follows typo, so clipping still happens at typo bounds (observed on Word for Windows 11).
- **UI bias:** Centering caps in typo/hhea helps web UI; script fonts with low x-height or tall swashes may need a different balance.
- **No target line height:** GF is “exceed these glyphs,” not “start from 1.5× UPM.” Reaching a specific default lineheight takes extra understanding.

GF metrics aren’t *bad*, but following them blindly can miss potential opportunities to do things in a more design-specific, user-oriented way.

## Goals

Ideal strategy properties:

- As consistent as practical across platforms and apps
- Intuitive to use and read in each major app
- Simple enough to describe and adapt for design goals

## Test approach

1. Glyphs source with per-export vertical metrics, plus measurement diagrams in glyph alternates (see below).
2. Build with FontMake.
3. Test exports in priority apps; store screenshots and notes here.
4. Optional later: contribution path for others’ screenshots.

**Priority apps:** Chrome (Safari/Firefox?), Mac TextEdit, InDesign, Illustrator, MS Word (Windows + Mac), Android?, iOS?

Test text (`?` / `!` hold metrics diagrams):

```
HẮÀbỵ? !
HẮÀbỵ?!
HẮÀbỵ? !
```

![Diagram of Vertical Metrics Test Glyph](docs/screenshots/vm-test-glyph-diagram.png)

## Test results

### InDesign

- Top alignment follows `typoAscender` regardless of `useTypoMetrics`.
- Default auto leading: 120% UPM (Changeable via **Justification → Auto Leading**).
- Cap-height (or basic ascender) `typoAscender` with `useTypoMetrics` False reads well; GF pushes an unintuitive gap at the top of frames.
- Overrides: Text Frame Options → Baseline Options → First Baseline.

![Test results in InDesign](docs/screenshots/screenshot-mac-indesign-260315.png)

### Illustrator

Vertical metrics barely affect alignment. By default, top offset follows lowercase ascenders.

- **Area Type:** top ≈ lowercase ascenders; selection highlight height ≈ typoAsc − typoDesc (gap ignored).
- **Point Type:** min top ≈ lowercase ascenders; frame grows for taller glyphs; min bottom ≈ lowest y in the font.
- Default leading: 120% UPM. Switching Point → Area Type can reflow to the top of the former point frame.

![Test results in Illustrator](docs/screenshots/screenshot-mac-illustrator-260322.png)

### macOS TextEdit (CoreText)

- Line height is `hheaDescender` to `hheaAscender`, when line spacing is set to "1.0" (the default). Higher values multiply the `hhea` total.
- Always based on `hhea`, even if `useTypoMetrics` is True.
- GF approaches land ~155% UPM vs ~140% for target-line-height approaches.
- Glyphs taller than `hheaAscender` will clip on the first line.

At Line Space 1.0:

![Vertical metrics tests in TextEdit, at Line Spacing 1.0](docs/screenshots/mac-textedit-vmtest-linespace_1.0-screenshot-260315.png)

At Line Space 1.2:

![Vertical metrics tests in TextEdit](docs/screenshots/mac-textedit-vmtest-linespace_1.2_default-screenshot-260315.png)

<details>
<summary>TextEdit still follows `hhea` when `useTypoMetrics` is True.</summary>

![TextEdit testing useTypoMetrics](docs/screenshots/mac-textedit-vmtest-linespace_1.0-useTypoMetrics-screenshot-260315.png)

</details>

<details>
<summary>hheaAscender below /Agrave → ~150% UPM fallback</summary>

macOS ignores `hhea` (and does not fall back to typo or win). Observed ~150% of UPM.

![Agrave exceeds hheaAscender](docs/screenshots/mac-textedit-vmtest-linespace_1.0-agrave_exceeds_agrave-screenshot-260315.png)

![Same, with tall win metrics](docs/screenshots/mac-textedit-vmtest-linespace_1.0-agrave_exceeds_agrave_tall_win_metrics-screenshot-260315.png)

</details>

Open checks: latest macOS; Agrave vs typoAsc when that differs from hheaAsc.

### Windows 11 Word

- Default: line spacing 1.08 + 8pt after paragraph. Use **Line Spacing: Single** to see metrics clearly.
- Uses `win`, or `typo` if `useTypoMetrics` True.
- Clipping: at typo when `useTypoMetrics` True; with False, generally no clip except tall parts of the first line on a page.
- Keep family names ≤ 31 characters or /Abreveacute may not show ([Font Bakery `name/family_and_style_max_length`](https://github.com/fonttools/fontbakery/blob/9a85e003d36ebfbbfe68c6d362e5db5a6434332c/Lib/fontbakery/checks/name/family_and_style_max_length.py)).

**Target Line Height B** fits best for consistency with other apps. GF works but runs tall and can clip anything taller than /Abreveacute (e.g. swashes).

Screenshots below use Line Spacing: Single.

![Windows 11 Word: Target 1400 B](docs/screenshots/win11-word-Target1400B.png)
![Windows 11 Word: Target 1400](docs/screenshots/win11-word-Target1400.png)
![Windows 11 Word: Google Fonts](docs/screenshots/win11-word-GF.png)

<details>
<summary>Additional Windows screenshots, including line spacing default settings panel</summary>

![Default line spacing settings](docs/screenshots/win11-word-linespace-options-defaults.png)
![GF Min](docs/screenshots/win11-word-GFMin.png)
![GF Min Alt](docs/screenshots/win11-word-GFMinAlt.png)
![Glyphs Default](docs/screenshots/win11-word-GlyphsDefault.png)

</details>

### Chrome & Firefox

- On Windows, follows `win`, or `typo` if `useTypoMetrics` 
- On Android, follows `hhea`, or `typo` if `useTypoMetrics` 
- On macOS, always uses `hhea` on macOS, even when `useTypeMetrics` is true. 
- Applies only when CSS `line-height` is unset; when set, line height is based on UPM, but relative positioning (i.e., centering) is derived from line metrics.

### Safari (macOS & iOS)

- Always uses `hhea`, even when `useTypeMetrics` is true. 

### Affinity

Tested on Mac, Mid June 26 (4557).

Default line height from `hhea` regardless of `useTypoMetrics`. Top alignment appears to follow lowercase ascender (/b)—needs more confirmation.

![Vertical metrics tests in Affinity](docs/screenshots/screenshot-mac-affinity-260622.png)

## Setting vertical metrics in font editors

### GlyphsApp

Set via Custom Parameters.

[Here’s a detailed guide.](https://glyphsapp.com/learn/vertical-metrics)

### RoboFont

Set in the Font Info > OpenType tab.

[Here’s a detailed guide.](https://robofont.com/documentation/reference/workspace/font-overview/font-info-sheet/opentype/)

### FontLab

[Here’s a detailed guide.](https://help.fontlab.com/fontlab/8/tutorials/calfonts/3.%20Fitting%20and%20Spacing/3b-1%20Ninety%20Second%20Vertical%20Metrics/)

Notes:
- FontLab font info calls typoAscender simply “ascender”. This should *not* match the drawn lowercase ascender on glyphs like `h` , as detailed above
    - Likewise, FontLab’s “descender” setting is the typoDescender.
- FontLab sets hhea to match OS/2 `typo` values by default, unless you check **Other Values > Custom hhea linespacing**
- FontLab calls winAscent the “Safe Top”
    - winDescent is set via “Safe Bottom”

## Note on CJK fonts

The [OpenType OS/2 typoAscender](https://learn.microsoft.com/en-us/typography/opentype/spec/os2#stypoascender) spec requires that for CJK fonts meant for vertical as well as horizontal layout, `sTypoAscender` describe the top of the ideographic em-box. Not tested here yet; future CJK work should treat that as required.

## Build

Requires Python ([python.org](https://www.python.org/)).

```sh
make setup
make build
```

## Possible to-do items

- [ ] Variable fonts: aside from `hheaLineGap` being ignored in variable fonts on macOS, are variable fonts handled differently from static fonts in any key apps/contexts?
- [ ] Web metrics: Re-test and confirm details; add screenshots with and without CSS `line-height`; compare Firefox/Safari.
- [ ] Double-check Adobe app behavior on Windows – it is very likely the same as on Mac, but this wasn’t tested here.

## Contributing

This project cannot cover every metrics × app × OS combination. It prioritizes environments that matter for type design aimed at graphic design, agencies, and brands.

Suggestions and questions: [open an Issue](https://github.com/arrowtype/vertical-metrics/issues). New tests with screenshots, notes, and app/OS versions are especially welcome. Typos and small fixes: [Pull Requests](https://github.com/arrowtype/vertical-metrics/pulls).

## Credits

Thanks to:

- [The Type Founders](https://thetypefounders.com/), for supporting this research and open publication
- [Google Fonts](https://fonts.google.com/), for informing the approach and for foundational tooling
- José Solé of [Dogray Type Foundry](https://www.dograytype.com/), for pushing a rethink of prior assumptions
- [ArrowType](https://www.arrowtype.com/) (Stephen Nixon), for design, writing, and testing

## Background resources

- [OpenType Spec: OS/2 Table](https://learn.microsoft.com/en-us/typography/opentype/spec/os2)
- [OpenType Spec: hhea Table](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea)
- [OpenType Spec: Recommendations](https://learn.microsoft.com/en-us/typography/opentype/spec/recom#tad)
- [Google Fonts Guide: Vertical Metrics](https://googlefonts.github.io/gf-guide/metrics.html)
- [GlyphsApp article on Vertical Metrics](https://glyphsapp.com/learn/vertical-metrics)
